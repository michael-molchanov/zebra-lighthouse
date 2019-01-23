FROM ubuntu:18.04

LABEL maintainer "Michael Molchanov <mmolchanov@adyax.com>"

USER root

RUN  echo "deb http://archive.ubuntu.com/ubuntu bionic main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

# SSH config.
RUN mkdir -p /root/.ssh
ADD config/ssh /root/.ssh/config
RUN chown root:root /root/.ssh/config && chmod 600 /root/.ssh/config

# Install base.
RUN apt-get update \
  && apt-get -y install \
  bash \
  build-essential \
  bzip2 \
  ca-certificates \
  curl \
  fuse \
  git-core \
  gnupg2 \
  grep \
  gzip \
  jq \
  language-pack-en-base \
  libbz2-dev \
  libffi-dev \
  libfreetype6 \
  libfreetype6-dev \
  libmcrypt-dev \
  libpng-dev \
  libxml2-dev \
  libxslt-dev \
  make \
  mysql-client \
  openssh-client \
  openssl \
  patch \
  procps \
  postgresql-client \
  python \
  python-crcmod \
  python-pip \
  python-wheel \
  python3-crcmod \
  python3-pip \
  python-wheel \
  rsync \
  software-properties-common \
  sqlite \
  strace \
  tar \
  tzdata \
  unzip \
  wget \
  && rm -rf /var/lib/apt/lists/* \
  && pip install yq requests

ENV LANGUAGE=en
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN locale-gen en_US.UTF-8

ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

COPY --from=hairyhenderson/gomplate:v3.1.0-slim /gomplate /bin/gomplate

# Install goofys
ENV GOOFYS_VERSION 0.19.0
RUN curl --fail -sSL -o goofys https://github.com/kahing/goofys/releases/download/v${GOOFYS_VERSION}/goofys \
  && mv goofys /usr/local/bin/ \
  && chmod +x /usr/local/bin/goofys


# Install fd
ENV FD_VERSION 7.2.0
RUN curl --fail -sSL -o fd.tar.gz https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz \
  && tar -zxf fd.tar.gz \
  && cp fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd /usr/local/bin/ \
  && rm -f fd.tar.gz \
  && rm -fR fd-v${FD_VERSION}-x86_64-unknown-linux-musl \
  && chmod +x /usr/local/bin/fd

ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG CHROME_DRIVER_VERSION="latest"
RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
  && echo "Using chromedriver version: "$CD_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/chromedriver /opt/chromedriver-$CD_VERSION \
  && chmod 755 /opt/chromedriver-$CD_VERSION \
  && ln -fs /opt/chromedriver-$CD_VERSION /usr/bin/chromedriver

# Install nodejs & grunt.
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y nodejs yarn \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g gulp-cli grunt-cli bower lighthouse \
  && grunt --version \
  && gulp --version \
  && bower --version \
  && yarn versions \
  && lighthouse --version
