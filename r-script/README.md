# R Script to update data on schedule

The data used as an example has been taken from the [MIT Election Data + Science Lab](https://electionlab.mit.edu/data), specifically this git repo: [2018-elections-unofficial](https://github.com/MEDSL/2018-elections-unoffical/tree/master).


## Local development

```
docker compose up --build
```

Alternatively, you can run the Docker image locally to connect to another database server. Copy the `.Renviron.template` into a file `.Renviron` and update the environment variables with the values of the database server to connect to. You can pass the `.Renviron` file as a parameter to `docker run`. Note that the file `.Renviron` is excluded from version control (see `.gitignore` file).

```
docker compose build
docker run --rm -dit --env-file ./.Renviron --name r-script containerised-deployments-script:latest
```

Once you have the `.Renviron` file, you can run the project in RStudio and the environment variables defined in it will be loaded automatically into the R session.

### Clean-up resources

```
docker compose down
docker volume r-script_db-data
```

Or if you haven't used docker compose, you can stop the containers manually:
```
docker stop r-script
```

And if you haven't run the container with the label `--rm`, then remove it after being stopped:

```
docker rm r-script
```

## Remote DB set-up

1. Create DB. The database is created in AWS as an RDS Postgres one (see the [terraform](../terraform/) project).

1. Create minimum needed table. The `summary` table is the only manually created table:

    ```
    create table summary (
        state varchar,
        trump16 int,
        clinton16 int,
        otherpres16 int,
        insert_date varchar
    );
    ```

1. Populate the data.

    To create the table in the remote DB with the data from the CSV file:

    ```
    df <- read.csv("../data/2018-elections-unofficial/election-context-2018.csv")
    pool <- do.call(pool::dbPool, config::get("dbConnectionArgs"))
    dplyr::copy_to(pool, df, "us_elections_2018_unofficial", overwrite = TRUE, temporary = FALSE)
    pool::poolClose(pool)
    ```

    Where `config::get("dbConnectionArgs")` is defined as:

    ```
    !expr list(drv = RPostgres::Postgres(), dbname = "US_Elections_2018", host = "containerised-deployments-test.cyphtuzbihyz.ap-southeast-2.rds.amazonaws.com", port = 5432, user = "epidb", password = "____")
    ```

## Deployment to AWS

1. Publish Docker images to ECR:

```
aws ecr get-login-password --region ap-southeast-2 --profile <your-profile-name> | docker login --username AWS --password-stdin 910733845259.dkr.ecr.ap-southeast-2.amazonaws.com
docker tag containerised-deployments-script:latest 910733845259.dkr.ecr.ap-southeast-2.amazonaws.com/containerised-deployments:r-script
docker push 910733845259.dkr.ecr.ap-southeast-2.amazonaws.com/containerised-deployments:r-script
```

