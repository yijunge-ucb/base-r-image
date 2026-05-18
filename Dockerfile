FROM us-central1-docker.pkg.dev/ucb-datahub-2018/base-images-repo/base-python-image:bbe5fda

# -------------------------------
# Environment for R
# -------------------------------

ENV R_LIBS_USER=/srv/r
ENV CONDA_DIR=/srv/conda/envs/notebook
# Add littler to PATH
ENV PATH=${CONDA_DIR}/lib/R/library/littler/bin:${CONDA_DIR}/bin:$PATH

# -------------------------------
# System packages for R
# -------------------------------
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        psmisc \
        sudo \
        libapparmor1 \
        lsb-release \
        libclang-dev \
        libpq5 \
        libgdal-dev \
        libgeos-c1t64 \
        libproj25 \
        libudunits2-0 \
        libxml2 \
        libcurl4-openssl-dev \
        libzmq5 \
        libzmq3-dev  > /dev/null

# -------------------------------
# R installation
# -------------------------------
ENV R_VERSION=4.4.2-1.2204.0
ENV LITTLER_VERSION=0.3.20-2.2204.0
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" > /etc/apt/sources.list.d/cran.list
RUN curl --silent --location --fail https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
    > /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN apt-get update -qq --yes && \
    apt-get install --yes -qq \
        r-base-core=${R_VERSION} \
        r-base-dev=${R_VERSION} \
        r-cran-littler=${LITTLER_VERSION} \
        littler=${LITTLER_VERSION} > /dev/null

# -------------------------------
# RStudio server installation
# -------------------------------
ENV RSTUDIO_URL=https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2024.04.2-764-amd64.deb
RUN curl --silent --location --fail ${RSTUDIO_URL} > /tmp/rstudio.deb && \
    apt install --no-install-recommends --yes /tmp/rstudio.deb && \
    rm /tmp/rstudio.deb

# -------------------------------
# Desktop packages for R GUI
# -------------------------------
RUN apt-get update -qq --yes && \
    apt-get install --yes -qq \
        dbus-x11 \
        firefox \
        xfce4 \
        xfce4-panel \
        xfce4-terminal \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme > /dev/null

# -------------------------------
# R environment tweaks
# -------------------------------
RUN mkdir -p ${R_LIBS_USER} && chown ${NB_USER}:${NB_USER} ${R_LIBS_USER}
RUN sed -i -e '/^R_LIBS_USER=/s/^/#/' /etc/R/Renviron && \
    echo "R_LIBS_USER=${R_LIBS_USER}" >> /etc/R/Renviron && \
    echo "TZ=${TZ}" >> /etc/R/Renviron

# -------------------------------
# IRkernel
# -------------------------------
COPY Rprofile.site /usr/lib/R/etc/Rprofile.site
COPY rsession.conf /etc/rstudio/rsession.conf
COPY rserver.conf /etc/rstudio/rserver.conf
COPY file-locks /etc/rstudio/file-locks

USER ${NB_USER}
RUN r -e "install.packages('IRkernel', version='1.2')" && \
    r -e "IRkernel::installspec(user = FALSE, prefix='${CONDA_DIR}')"

# -------------------------------
# R packages
# -------------------------------
COPY install.R /tmp/install.R
RUN r /tmp/install.R && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

