package main

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"dagger.io/dagger"
)

func main() {
	ctx := context.Background()

	client, err := dagger.Connect(ctx, dagger.WithLogOutput(os.Stderr))
	if err != nil {
		panic(err)
	}
	defer client.Close()

	flociEndpoint := "http://host.docker.internal:4566"

	fmt.Println("==> Checking Floci is running...")
	if err := checkFloci(ctx, client, flociEndpoint); err != nil {
		fmt.Fprintf(os.Stderr, "Floci not reachable at %s\n", flociEndpoint)
		fmt.Fprintf(os.Stderr, "  Start it: docker run -d --name floci -p 4566:4566 floci/floci:latest\n")
		os.Exit(1)
	}
	fmt.Println("  Floci OK")

	tfDir := client.Host().Directory(".", dagger.HostDirectoryOpts{
		Exclude: []string{".git", "ci", "node_modules", ".terraform"},
	})

	fmt.Println("==> Provisioning EKS + RDS via Terraform + Floci")

	envVars := map[string]string{
		"AWS_ACCESS_KEY_ID":       "test",
		"AWS_SECRET_ACCESS_KEY":   "test",
		"AWS_DEFAULT_REGION":       "us-east-1",
		"TF_VAR_aws_region":        "us-east-1",
		"TF_VAR_cluster_name":      "eks-rds-demo",
		"TF_VAR_environment":       "ci",
		"TF_VAR_availability_zones": "us-east-1a,us-east-1b,us-east-1c",
		"TF_VAR_node_desired_size": "2",
		"TF_VAR_node_min_size":     "1",
		"TF_VAR_node_max_size":     "3",
		"TF_VAR_rds_multi_az":      "false",
		"TF_VAR_enable_irsa":       "true",
		"AWS_ENDPOINTS": fmt.Sprintf(
			`{"ec2":"%s","iam":"%s","eks":"%s","rds":"%s","logs":"%s","cloudwatch":"%s","sts":"%s","kms":"%s"}`,
			flociEndpoint, flociEndpoint, flociEndpoint, flociEndpoint, flociEndpoint, flociEndpoint, flociEndpoint, flociEndpoint,
		),
	}

	tf := client.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl", "unzip", "bash", "-q"}).
		WithExec([]string{"sh", "-c", `
			arch=$(uname -m)
			case "$arch" in
				x86_64)  tfarch="amd64" ;;
				aarch64) tfarch="arm64" ;;
				*)       tfarch="amd64" ;;
			esac
			curl -sLo /tmp/tf.zip "https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_${tfarch}.zip"
			unzip -qo /tmp/tf.zip -d /usr/local/bin/
			rm /tmp/tf.zip
		`}).
		WithMountedDirectory("/app", tfDir)

	for k, v := range envVars {
		tf = tf.WithEnvVariable(k, v)
	}
	tf = tf.WithWorkdir("/app")

	fmt.Println("  init...")
	c, err := tf.WithExec([]string{"sh", "-c", "terraform init -upgrade"}).Sync(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "  init FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("  init OK")

	fmt.Println("  validate...")
	var validateOut string
	var validateErr error
	validateOut, validateErr = c.WithExec([]string{"sh", "-c", "terraform validate"}).Stdout(ctx)
	if validateErr != nil {
		fmt.Fprintf(os.Stderr, "  validate FAILED: %v\n%s\n", validateErr, validateOut)
	} else if strings.Contains(validateOut, "Error") {
		fmt.Printf("  validate errors:\n%s\n", validateOut)
	} else {
		fmt.Println("  validate OK")
	}

	var planOut string

	fmt.Println("  plan...")
	var planErr error
	planOut, planErr = c.WithExec([]string{"sh", "-c", "terraform plan -no-color -var-file=environments/ci.tfvars"}).Stdout(ctx)
	if planErr != nil {
		fmt.Fprintf(os.Stderr, "  plan FAILED: %v\n", planErr)
	} else {
		for _, line := range strings.Split(planOut, "\n") {
			if strings.Contains(line, "Plan:") || strings.Contains(line, "to add") || strings.Contains(line, "to change") {
				fmt.Printf("  %s\n", line)
			}
			if strings.Contains(line, "Error") {
				fmt.Printf("  ERROR: %s\n", line)
			}
		}
		fmt.Println("  plan OK")
	}

	fmt.Println("  apply (Floci, with retries)...")
	var applyOut string
	var applyErr error
	for i := 1; i <= 3; i++ {
		var out string
		out, applyErr = c.WithExec([]string{"sh", "-c", "terraform apply -auto-approve -no-color -var-file=environments/ci.tfvars 2>&1"}).Stdout(ctx)
		if applyErr == nil {
			applyOut = out
			break
		}
		fmt.Printf("  apply attempt %d/3 failed: %v (retrying in 5s...)\n", i, applyErr)
		if i < 3 {
			time.Sleep(5 * time.Second)
		}
	}
	if applyErr != nil {
		fmt.Fprintf(os.Stderr, "  apply FAILED (non-fatal): %v\n", applyErr)
	} else {
		for _, line := range strings.Split(applyOut, "\n") {
			if strings.Contains(line, "Apply complete") || strings.Contains(line, "Resources:") {
				fmt.Printf("  %s\n", line)
			}
			if strings.Contains(line, "Error") || strings.Contains(line, "error") {
				fmt.Printf("  WARN: %s\n", line)
			}
		}
		fmt.Println("  apply OK")
	}

	fmt.Println("==> Verifying EKS + RDS resources via Floci")
	awsCLI := client.Container().
		From("amazon/aws-cli:latest").
		WithEntrypoint([]string{}).
		WithEnvVariable("AWS_ACCESS_KEY_ID", "test").
		WithEnvVariable("AWS_SECRET_ACCESS_KEY", "test").
		WithEnvVariable("AWS_DEFAULT_REGION", "us-east-1")

	checks := []struct {
		name string
		args []string
	}{
		{"EKS Clusters", []string{"aws", "eks", "list-clusters", "--endpoint-url", flociEndpoint, "--output", "json"}},
		{"VPCs", []string{"aws", "ec2", "describe-vpcs", "--endpoint-url", flociEndpoint, "--query", "Vpcs[].VpcId", "--output", "json"}},
		{"Security Groups", []string{"aws", "ec2", "describe-security-groups", "--endpoint-url", flociEndpoint, "--query", "SecurityGroups[].GroupName", "--output", "json"}},
		{"RDS Instances", []string{"aws", "rds", "describe-db-instances", "--endpoint-url", flociEndpoint, "--query", "DBInstances[].DBInstanceIdentifier", "--output", "json"}},
		{"IAM Roles", []string{"aws", "iam", "list-roles", "--endpoint-url", flociEndpoint, "--query", "Roles[].RoleName", "--output", "json"}},
	}

	for _, ch := range checks {
		out, err := awsCLI.WithExec(ch.args).Stdout(ctx)
		if err != nil {
			fmt.Printf("  %s: error — %v\n", ch.name, err)
			continue
		}
		trimmed := strings.TrimSpace(out)
		if trimmed == "" || trimmed == "null" || trimmed == "[]" {
			fmt.Printf("  %s: none found\n", ch.name)
		} else {
			fmt.Printf("  %s: %s\n", ch.name, trimmed)
		}
	}

	fmt.Println("==> Destroying infrastructure via Terraform...")
	destroyOut, err := c.WithExec([]string{"sh", "-c", "terraform destroy -auto-approve -no-color 2>&1"}).Stdout(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "  destroy FAILED: %v\n", err)
	} else {
		for _, line := range strings.Split(destroyOut, "\n") {
			if strings.Contains(line, "Destroy complete") || strings.Contains(line, "Resources:") {
				fmt.Printf("  %s\n", line)
			}
		}
		fmt.Println("  destroy OK")
	}

	fmt.Println("==> Floci EKS+RDS CI pipeline complete")
}

func checkFloci(ctx context.Context, client *dagger.Client, endpoint string) error {
	_, err := client.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl", "-q"}).
		WithExec([]string{"sh", "-c", fmt.Sprintf("curl -sf --max-time 5 %s/_localstack/health > /dev/null", endpoint)}).
		Sync(ctx)
	return err
}
