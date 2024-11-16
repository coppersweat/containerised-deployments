# Load needed R packages
library(pool)

# Set up the database pool connection
#
# Two different DB connections are being set up in the "config.yml" file:
#
#   - [local] One for local development, with a PostgreSQL database running
#     on another container on the side to the application initialised from 
#     a CSV file (data/election-context-2018.csv). This would be equivalent
#     as running:
#
#        pool <- dbPool(
#          drv = RPostgres::Postgres(),
#          dbname = "US_Elections_2018",
#          host = "r-script-database-1",
#          port = 5432,
#          user = "epidb",
#          password = "____"
#        )
#
#   - [default] And another for AWS RDS Postgres with the containerised 
#     application running in the cloud. This would be equivalent as running:
#
#        pool <- dbPool(
#          drv = odbc::odbc(),
#          dsn = "snowodbc",
#          server = Sys.getenv("SNOWFLAKE_HOST"),
#          account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
#          authenticator = "OAUTH",
#          token = readLines("/snowflake/session/token"), # OAuth token file, created by SPCS
#          warehouse = "CONTAINER_HOL_WH",
#          database = "CONTAINER_HOL_DB",
#          schema = "PUBLIC"
#        )
#
# The environment variable "R_CONFIG_ACTIVE" determines which one to use. 
# By default, the connection to RDS Postgres will be used, and the local one 
# is being set up in the "docker-compose.yaml" file.
pool <- do.call(dbPool, config::get("dbConnectionArgs"))

# SQL statement to insert one row to the summary table
new_row_sql <- "
    insert into summary (state, trump16, clinton16, otherpres16, insert_date)
    select * from (
        select state, sum(trump16), sum(clinton16), sum(otherpres16), now()
        from US_elections_2018_unofficial
        group by state
    ) t
    where not exists 
        (select 1 
        from summary
        where state = t.state)
    order by state
    limit 1;"

# Insert a new row in the summary table
dbExecute(pool, new_row_sql)

# Query the summary table to get the latest entries
get_summary_sql <- "
    select state, trump16, clinton16, otherpres16, insert_date
    from summary
    order by insert_date desc;"
data <- dbGetQuery(pool, get_summary_sql)
message("Summary data: ")
head(data)

# Shut down the pool
poolClose(pool)
