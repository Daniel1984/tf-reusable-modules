# terraform

Collection of shared Terraform modules

### Reusable terraform lambda module

Can be used in 2 different ways:

1. **RECOMMENDED**: by letting terraform build lambas. In this case you must:

   - pass in `tf_build = true` variable
   - pass in `lambda_dir` variable, a path to lambda dir relative to main tf module e.g. ../cmd/profile-events-writer

   ```tf
    # Example usage
    module "sample_lambda" {
      source        = "git::https://git.sussexdirectories.com/shared/phi/terraform.git//lambda?ref=v1.0.0"
      lambda_dir    = "../../api/lambdas/sample"
      tf_build      = true
      function_name = "sample"
      description   = "sample lambda"
      role_arn      = aws_iam_role.role.arn
    }
   ```

2. **NOT RECOMMENDED**: by passing precompiled package name as `zip_package_filename` variable. In this case you must build lambdas in CI:

   ```tf
   # Example usage
   module "sample_lambda" {
     source               = "git::https://git.sussexdirectories.com/shared/phi/terraform.git//lambda?ref=v1.0.0"
     zip_package_filename = "../../api/lambdas/sample/main.zip"
     function_name        = "sample"
     description          = "sample lambda"
     role_arn             = aws_iam_role.role.arn
   }
   ```
