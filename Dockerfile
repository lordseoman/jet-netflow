FROM debian:jessie-slim

MAINTAINER Simon Hookway <simon@obsidian.com.au>

ENV DEBIAN_FRONTEND noninteractive

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG TIMEZONE
ARG DF_VOLUMES
ARG DF_PORTS
ARG CLIENT
ARG SERVERNAME
ARG IP
ARG FQDN

ENV http_proxy ${HTTP_PROXY:-}
ENV https_proxy ${HTTPS_PROXY:-}
ENV CLIENT ${CLIENT:-}
ENV SERVERNAME ${SERVERNAME:-}
ENV IP ${IP:-}
ENV FQDN ${FQDN:-}

COPY jet-conf/obsidian.list /etc/apt/sources.list.d/
COPY jet-conf/debian.list /etc/apt/sources.list
COPY skel/.bashrc /root/
COPY skel/.vimrc /root/
COPY skel/.screenrc /root/

RUN apt-get clean \
  && apt-get update \
  && apt-get install --yes net-tools screen vim wget tcpdump \
  && updatedb

# Fix timezone
RUN rm /etc/localtime \
  && ln -sv /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata

ENV NFDUMP_VERSION 1.6.9-exinda
WORKDIR /tmp
COPY nfdump-$NFDUMP_VERSION.tar.gz ./

RUN apt-get update \
  && apt-get install --yes --no-install-recommends build-essential gcc make flex byacc libbz2-dev \
  && tar -zxf nfdump-$NFDUMP_VERSION.tar.gz \
  && rm nfdump-$NFDUMP_VERSION.tar.gz \
  && cd nfdump-$NFDUMP_VERSION \
  && ./configure --enable-nsel=yes --enable-shared=false \
  && make \
  && make install \
  && cd .. \
  && rm -rf nfdump-$NFDUMP_VERSION \
  && apt-get remove --yes build-essential gcc make \
  && apt-get autoremove --yes

# Add the proxy to /etc/bash.bashrc
RUN apt-get install --yes ca-certificates python python-setuptools python-dev \
  && easy_install watchdog

ENV HOME /opt/netflowv9
RUN useradd --create-home --home-dir $HOME --shell /bin/bash --uid 1001 jet 
COPY skel/ $HOME/

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER jet
WORKDIR $HOME

STOPSIGNAL SIGTERM

VOLUME ["/Netflow", "/opt/Usage", "/opt/Archive"]
EXPOSE 9995

CMD ["start"]

