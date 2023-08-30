# terraform

Collection of shared Terraform modules

### lambda/

Reusable terraform lambda module

Can be used in 2 different ways:

1. By letting terraform build lambas (recommended). In this case you must:

   - pass in `tf_build = true` variable
   - pass in `lambda_dir` variable, a path to lambda dir relative to main tf module e.g. ../cmd/profile-events-writer

2. By passing precompiled package name as `zip_package_filename` variable. In this case you must build lambdas in CI. (NOT recommended)
