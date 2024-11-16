# Based on Ubuntu 22.04
FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
  # System dependency for R package RPostgres
  libpq5 \
  # Cron, to run the R script on schedule
  cron \
  # Clean up unnecessary files and set up time zone
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && echo 'Pacific/Auckland' > /etc/timezone \
  && rm /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata

# Remove the base R packages pre-installed with R 
# and install the needed R packages to run the script.
COPY renv.lock .
RUN --mount=type=cache,target=/root/.cache/R/renv R -e "\
  remove.packages(\
    pkgs = subset(\
      as.data.frame(installed.packages()), \
      is.na(Priority) | Priority == 'recommended'\
    )[['Package']], \
    lib = .libPaths()\
  ); \
  install.packages('renv'); \
  renv::restore(repos = 'https://packagemanager.posit.co/cran/__linux__/jammy/latest')" \
  && rm -f renv.lock

WORKDIR /root

# The database connection configuration
COPY ./config.yml /root/config.yml

# The R script to be run on schedule
COPY ./update-data.R /root/update-data.R

# Crontab file copied to cron.d directory.
COPY ./cronjob /etc/cron.d/update-database

# Give needed permissions to run the cron job
# and create log file.
RUN chmod u+x /etc/cron.d/update-database \
  && chmod u+x /root/update-data.R \
  && mkdir -p /var/log/rscript \
  && touch /var/log/rscript/update-data.Rout

# Pass environment variables to the cron job. Then, start cron and follow
# the logs file until the container is stopped.
CMD [ "/bin/bash", "-c", "env >> /etc/environment && cron && tail -f /var/log/rscript/update-data.Rout" ]
