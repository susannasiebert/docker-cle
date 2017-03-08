FROM ubuntu:xenial
MAINTAINER Susanna Kiwala <ssiebert@wustl.edu>

LABEL \
    description="Image for tools used in the CLE"

RUN apt-get update -y

##########
#GATK 3.6#
##########
RUN apt-get install -y wget default-jdk git unzip
ENV maven_package_name apache-maven-3.3.9
ENV gatk_dir_name gatk-protected
ENV gatk_version 3.6
RUN cd /tmp/ && wget -q http://mirror.nohup.it/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip

# LSF: Comment out the oracle.jrockit.jfr.StringConstantPool.
RUN cd /tmp/ \
    && git clone --recursive https://github.com/broadgsa/gatk-protected.git \
    && cd /tmp/gatk-protected && git checkout tags/${gatk_version} \
    && sed -i 's/^import oracle.jrockit.jfr.StringConstantPool;/\/\/import oracle.jrockit.jfr.StringConstantPool;/' ./public/gatk-tools-public/src/main/java/org/broadinstitute/gatk/tools/walkers/varianteval/VariantEval.java \
    && mv /tmp/gatk-protected /opt/${gatk_dir_name}-${gatk_version}
RUN cd /opt/ && unzip /tmp/${maven_package_name}-bin.zip \
    && rm -rf /tmp/${maven_package_name}-bin.zip LICENSE NOTICE README.txt \
    && cd /opt/ \
    && cd /opt/${gatk_dir_name}-${gatk_version} && /opt/${maven_package_name}/bin/mvn verify -P\!queue \
    && mv /opt/${gatk_dir_name}-${gatk_version}/protected/gatk-package-distribution/target/gatk-package-distribution-${gatk_version}.jar /opt/GenomeAnalysisTK.jar \
    && rm -rf /opt/${gatk_dir_name}-${gatk_version} /opt/${maven_package_name}

###############
#Strelka 2.7.1#
###############
RUN apt-get update && apt-get install -y \
    bzip2 \
    g++ \
    make \
    perl-doc \
    python \
    rsync \
    wget \
    zlib1g-dev

ENV STRELKA_INSTALL_DIR /opt/strelka/

RUN wget https://github.com/Illumina/strelka/releases/download/v2.7.1/strelka-2.7.1.centos5_x86_64.tar.bz2 \
    && tar xf strelka-2.7.1.centos5_x86_64.tar.bz2 \
    && rm -f strelka-2.7.1.centos5_x86_64.tar.bz2 \
    && mv strelka-2.7.1.centos5_x86_64 $STRELKA_INSTALL_DIR

#strelka requires a couple steps to run, so add a helper script to sequence those
COPY strelka_helper.pl /usr/bin/

###############
#Varscan 2.4.2#
###############
RUN apt-get update && apt-get install -y \
    default-jre \
    wget

ENV VARSCAN_INSTALL_DIR=/opt/varscan

WORKDIR $VARSCAN_INSTALL_DIR
RUN wget https://github.com/dkoboldt/varscan/releases/download/2.4.2/VarScan.v2.4.2.jar && \
    ln -s VarScan.v2.4.2.jar VarScan.jar

##############
#HTSlib 1.3.2#
##############
ENV HTSLIB_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 && \
    tar --bzip2 -xvf htslib-1.3.2.tar.bz2

WORKDIR /tmp/htslib-1.3.2
RUN ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR/software/htslib-1.3.2 && \
    make && \
    make install

################
#Samtools 1.3.1#
################
RUN apt-get update && apt-get install -y \
    bzip2 \
    g++ \
    make \
    ncurses-dev \
    wget \
    zlib1g-dev

ENV SAMTOOLS_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
RUN wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
    tar --bzip2 -xf samtools-1.3.1.tar.bz2

WORKDIR /tmp/samtools-1.3.1
RUN ./configure --with-htslib=$SAMTOOLS_INSTALL_DIR/software/htslib-1.3.2 --prefix=$SAMTOOLS_INSTALL_DIR && \
    make && \
    make install

WORKDIR /
RUN rm -rf /tmp/samtools-1.3.1

################
#Pindel 0.2.5b8#
################
RUN apt-get update && apt-get install -y \
    bzip2 \
    wget \
    make \
    ncurses-dev \
    zlib1g-dev \
    g++

WORKDIR /opt
RUN wget https://github.com/genome/pindel/archive/v0.2.5b8.tar.gz && \
    tar -xzf v0.2.5b8.tar.gz

WORKDIR /opt/pindel-0.2.5b8
RUN ./INSTALL $SAMTOOLS_INSTALL_DIR/software/htslib-1.3.2

WORKDIR /
RUN ln -s /opt/pindel-0.2.5b8/pindel /usr/bin/pindel
RUN ln -s /opt/pindel-0.2.5b8/pindel2vcf /usr/bin/pindel2vcf

##########
#fpfilter#
##########
COPY fpfilter.pl /usr/bin/fpfilter.pl

#######
#tabix#
#######
RUN ln -s $SAMTOOLS_INSTALL_DIR/bin/tabix /usr/bin/tabix

########
#VEP 86#
########
RUN apt-get update && \
    apt-get install -y \
    bioperl \
    wget \
    unzip \
    libfile-copy-recursive-perl \
    libarchive-extract-perl \
    libarchive-zip-perl \
    libapache-dbi-perl \
    curl

RUN mkdir /opt/vep/

WORKDIR /opt/vep
RUN wget https://github.com/Ensembl/ensembl-tools/archive/release/86.zip && \
    unzip 86.zip

WORKDIR /opt/vep/ensembl-tools-release-86/scripts/variant_effect_predictor/
RUN perl INSTALL.pl --NO_HTSLIB

WORKDIR /
RUN ln -s /opt/vep/ensembl-tools-release-86/scripts/variant_effect_predictor/variant_effect_predictor.pl /usr/bin/variant_effect_predictor.pl


RUN apt-get install -y libnss-sss
RUN ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

#LSF: Java bug that need to change the /etc/timezone.
#     The above /etc/localtime is not enough.
RUN echo "America/Chicago" > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata
