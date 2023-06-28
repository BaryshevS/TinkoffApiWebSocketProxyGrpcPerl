FROM ubuntu:23.04
MAINTAINER nfggroup <support@nfggroup.ru>

ENV TZ Europe/Moscow
RUN echo "Europe/Moscow" > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends tzdata

RUN dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && \
    apt-get install -y \
        cpanminus curl wget unzip zip bzip2 tar \
        apt \
        build-essential \
        ssl-cert \
        gcc binutils make linux-headers-generic

RUN apt-get install -y gcc make libwww-perl libdbi-perl libjson-perl libarchive-zip-perl zip tar bzip2 lsb-release libyaml-perl build-essential gcc binutils make \
    checkinstall build-essential autoconf automake gcc binutils make libc6-dev linux-headers-generic libncurses5-dev libcpan-meta-perl
RUN cpanm \
    ExtUtils::MakeMaker \
    ExtUtils::Install \
    Module::Build

RUN  apt-get install -y libwww-perl  libjson-perl \
     libncurses5-dev libyaml-perl libmodule-install-perl libany-moose-perl libclass-method-modifiers-perl \
     libdata-types-perl libdatetime-perl libfile-slurp-perl libtest-exception-perl libtry-tiny-perl libboolean-perl libanyevent-perl

RUN cpanm AnyEvent::WebSocket::Client \
    AnyEvent::Promises

RUN cpanm \
    DDP

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./sockettest.pl /home/sockettest.pl

CMD perl /home/sockettest.pl -v