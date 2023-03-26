<!-- BEGIN_TF_DOCS -->
# README #

## Description

**Version**: 1.0
Terraform network resources

Some more information can go here.

## Documentation

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 4.49 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.60.0 |



### Resources

| Name | Type |
|------|------|
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |





## Contribute

### Bug Reports & Feature Requests

Write to michaelcapponi96@gmail.com

### Release process
1. Start a new release: `git flow release start x.y.z`
2. Update version at *line 4* in `main.tf`
3. Update CHANGELOG.md with relevant changes
4. Rebuild the docs:
    The README.md is built with terraform-docs. To install follow the instruction [here](https://terraform-docs.io/user-guide/installation/).
    ```bash
    terraform-docs .
    ```
5. Check that only *.md* files have changed: `git status`
5. Commit
6. Finish the release: `git flow release finish x.y.z`
7. Push code and tags: `git push master; git push develop; git push --tags`

## Changelog
Check here the [CHANGELOG](CHANGELOG.md)
<!-- END_TF_DOCS -->