# Based on Ubuntu 22.04
FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
  # System dependency for R package RPostgres
  libpq5 \
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

# Set Shiny options globally
RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" > "${R_HOME}/etc/Rprofile.site"

# Create system user "app" to run the application 
# and change working directory to its home folder.
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /home/app

# Copy application into the image
COPY app .

# Give ownership of the application to the "app" user
RUN chown app:app -R /home/app

# Set the running user to "app"
USER app

# Expose Shiny's default port
EXPOSE 3838

# Run Shiny application
CMD ["R", "-e", "shiny::runApp('/home/app')"]