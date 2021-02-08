# Canvas DynamoDB

An opinionated way to talk to Dynamo tables.

## Features

- *Query Logging* : statements that get executed will get written to rails debug logs
- *Batch Operations*: Useful helper methods for building batched read/write queries.
- *Table Naming Conventions*: using prefixes and semantic names.

## Intentional Omissions!

We don't want to manage the tables themselves.  A DynamoDB table is
more like a database than a schema change.  It should be
managed in terraform and scaled by devops tooling.