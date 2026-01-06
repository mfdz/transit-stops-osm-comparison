# Troubleshooting

# Error: Environment 'prod' was not found.
When `make compare` fails with an `Environment 'prod' was not found.` error, the database was not fully created, e.g. because `make compare` was run before the data was downloaded. If that happens, you may either delete the database and retry, or execute 

```sh

```
