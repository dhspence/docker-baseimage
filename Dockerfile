FROM ubuntu:xenial
MAINTAINER David Spencer <dspencer@wustl.edu>

LABEL Image for basic ad-hoc bioinformatic analyses

#some basic tools
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    bzip2 \
    curl \
    default-jdk \
    default-jre \
    g++ \
    git \
    less \
    libcurl4-openssl-dev \
    libpng-dev \
    libssl-dev \
    libxml2-dev \
    make \
    ncurses-dev \
    nodejs \
    pkg-config \
    python \
    python-dev \
    virtualenv \
    python-pip \
    rsync \
    unzip \
    wget \
    zip \
    zlib1g-dev \
    bc \
    tzdata

# needed for MGI data mounts
RUN apt-get update && apt-get install -y libnss-sss && apt-get clean all

#set timezone to CDT
RUN ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
#LSF: Java bug that need to change the /etc/timezone.
#     The above /etc/localtime is not enough.
RUN echo "America/Chicago" > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

# some other utils
RUN apt-get update && apt-get install -y --no-install-recommends gawk openssh-client grep evince && apt-get clean all

##############
#Picard
##############
ENV picard_version 2.12.1

# Assumes Dockerfile lives in root of the git repo. Pull source files into
# container
RUN apt-get update && apt-get install ant --no-install-recommends -y && \
    cd /usr/ && \
    git config --global http.sslVerify false && \
    git clone --recursive https://github.com/broadinstitute/picard.git && \
    cd /usr/picard && \
    git checkout tags/${picard_version} && \
    ./gradlew shadowJar && \
    cp ./build/libs/picard.jar . && \
    echo -e '#!/bin/bash'"\n"'java -Xmx16g -jar /usr/picard/picard.jar $@' > /usr/local/bin/picard && \
    chmod a+x /usr/local/bin/picard

##############
# Samtools
##############

ENV SAMTOOLS_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
RUN wget https://github.com/samtools/samtools/releases/download/1.5/samtools-1.5.tar.bz2 && \
  tar --bzip2 -xf samtools-1.5.tar.bz2

WORKDIR /tmp/samtools-1.5
RUN ./configure --enable-plugins --prefix=$SAMTOOLS_INSTALL_DIR && \
  make all all-htslib && \
  make install install-htslib

WORKDIR /
RUN ln -s $SAMTOOLS_INSTALL_DIR/bin/samtools /usr/bin/samtools && \
  rm -rf /tmp/samtools-1.5


##############
## bedtools ##

WORKDIR /usr/local
RUN git clone https://github.com/arq5x/bedtools2.git && \
    cd /usr/local/bedtools2 && \
    git checkout v2.25.0 && \
    make && \
    ln -s /usr/local/bedtools2/bin/* /usr/local/bin/

##############
## vcftools ##
ENV ZIP=vcftools-0.1.14.tar.gz
ENV URL=https://github.com/vcftools/vcftools/releases/download/v0.1.14/
ENV FOLDER=vcftools-0.1.14
ENV DST=/tmp

RUN wget $URL/$ZIP -O $DST/$ZIP && \
    tar xvf $DST/$ZIP -C $DST && \
    rm $DST/$ZIP && \
    cd $DST/$FOLDER && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf $DST/$FOLDER


##################
# ucsc utilities #
RUN mkdir -p /tmp/ucsc && \
    cd /tmp/ucsc && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigAverageOverBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && \
    chmod ugo+x * && \
    mv * /usr/local/bin/

