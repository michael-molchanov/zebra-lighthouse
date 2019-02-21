FROM fedora:29

LABEL maintainer "Michael Molchanov <mmolchanov@adyax.com>"

USER root

# SSH config.
RUN mkdir -p /root/.ssh
ADD config/ssh /root/.ssh/config
RUN chown root:root /root/.ssh/config && chmod 600 /root/.ssh/config
ADD google-chrome.repo /etc/yum.repos.d/google-chrome.repo

# Install base.
RUN dnf upgrade --refresh -y \
  && dnf groupinstall -y "Development Tools" "Development Libraries" \
  && dnf install -y \
  bash \
  bzip2 \
  ca-certificates \
  curl \
  fuse \
  git-core \
  gnupg2 \
  grep \
  gzip \
  jq \
  bzip2-devel \
  libffi-devel \
  freetype \
  freetype-devel \
  libmcrypt-devel \
  libpng-devel \
  libxml2-devel \
  libxslt-devel \
  make \
  openssh \
  openssl \
  patch \
  procps \
  python3-pip \
  python3-wheel \
  rsync \
  sqlite \
  strace \
  tar \
  tzdata \
  unzip \
  wget \
  && pip3 install yq requests

COPY --from=hairyhenderson/gomplate:v3.1.0-slim /gomplate /bin/gomplate

# Install goofys
ENV GOOFYS_VERSION 0.19.0
RUN curl --fail -sSL -o goofys https://github.com/kahing/goofys/releases/download/v${GOOFYS_VERSION}/goofys \
  && mv goofys /usr/local/bin/ \
  && chmod +x /usr/local/bin/goofys


# Install fd
ENV FD_VERSION 7.2.0
RUN curl --fail -sSL -o fd.tar.gz https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
  && tar -zxf fd.tar.gz \
  && cp fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd /usr/local/bin/ \
  && rm -f fd.tar.gz \
  && rm -fR fd-v${FD_VERSION}-x86_64-unknown-linux-gnu \
  && chmod +x /usr/local/bin/fd

ARG CHROME_VERSION="google-chrome-stable"
RUN dnf install --refresh -y ${CHORME_VERSION:-google-chrome-stable}

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
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
  && curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
  && dnf install --refresh -y nodejs yarn \
  && npm install -g gulp-cli grunt-cli bower lighthouse \
  && grunt --version \
  && gulp --version \
  && bower --version \
  && yarn versions \
  && lighthouse --version
