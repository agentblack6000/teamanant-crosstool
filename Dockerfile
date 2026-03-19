# Starting from base image 
FROM ubuntu:22.04

ARG CTNG_UID=1000
ARG CTNG_GID=1000

# Add the directory where all of this will be setup
ARG CTNG_BUILD_DIR=/crosstool-chain-build

# Add the directory where the crosstool-ng repo will be cloned
ARG CTNG_SRC_DIR=/crosstool-chain-source

ARG CTNG_HOME_DIR=/crosstool-configs

RUN groupadd -g $CTNG_GID ctng
RUN useradd -d ${CTNG_HOME_DIR} -m -g ${CTNG_GID} -u ${CTNG_UID} -s /bin/bash ctng

# Setup PATH
ENV CTNG_BUILD_DIR=${CTNG_BUILD_DIR}
ENV PATH="${CTNG_BUILD_DIR}/bin:${PATH}"

# Non-interactive configuration of tzdata
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
RUN { echo 'tzdata tzdata/Areas select Etc'; echo 'tzdata tzdata/Zones/Etc select UTC'; } | debconf-set-selections

RUN apt-get update
RUN apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build

RUN git clone https://github.com/crosstool-ng/crosstool-ng.git ${CTNG_SRC_DIR}

# Source: https://crosstool-ng.github.io/docs/install/#clone
RUN cd ${CTNG_SRC_DIR} && \
    ./bootstrap && \
    ./configure --prefix=${CTNG_BUILD_DIR} && \
    make && \
    make install

# These lines are pretty useless, this would make more sense if this was running on a 
# server that handles the signals these lines pass to the child processes
# RUN wget -O /sbin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64
# RUN chmod a+x /sbin/dumb-init
# ENTRYPOINT [ "/sbin/dumb-init", "--" ]

USER ctng
WORKDIR ${CTNG_HOME_DIR}

RUN ct-ng arm-cortex_a8-linux-gnueabi
RUN ct-ng build