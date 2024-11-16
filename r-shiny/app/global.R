library(pool)
library(shiny)

# Set up the database pool connection
#
# Two different DB connections are being set up in the "config.yml" file:
#
#   - [local] One for local development, with a PostgreSQL database running
#     on another container on the side to the application initialised from 
#     a CSV file (db/init/data/summary-data.csv). This would be equivalent
#     as running:
#
#        pool <- dbPool(
#          drv = RPostgres::Postgres(),
#          dbname = "greenhouse-gas-emissions",
#          host = "r-shiny-database-1",
#          port = 5432,
#          user = "epi-db-user",
#          password = "____"
#        )
#
#   - [default] And another for Snowflake with the containerised application 
#     running on Snowpark Container Services. This would be equivalent as
#     running:
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
# The environment variable "R_CONFIG_ACTIVE" determines which one to use. By 
# default, the connection to Snowflake will be used, and the local one is being
# set up in the "docker-compose.yaml" file.
pool <- do.call(dbPool, config::get("dbConnectionArgs"))

# Shut down the pool when the app stops
onStop(function() {
  poolClose(pool)
})
