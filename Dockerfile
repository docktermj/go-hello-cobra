FROM centos:7.7.1908

ENV REFRESHED_AT 2019-11-16

# --- Install system packages -------------------------------------------------

# Avoid "Error: libselinux conflicts with fakesystemd-1-17.el7.centos.noarch"

RUN yum -y swap fakesystemd systemd \
 && yum -y install systemd-devel \
 && yum clean all

RUN yum -y update

# Install [base, ruby] dependencies.

RUN yum -y install \
    git \
    tar \
    wget \
 && yum -y install \
    gcc \
    glibc-static \
    libseccomp-static \
    make \
    rpm-build \
    ruby-devel \
    rubygems \
    which

# Install Effing Package Manager (FPM).

RUN gem install --no-ri --no-rdoc fpm

# --- Install Go --------------------------------------------------------------

ENV GO_VERSION=1.13.4

RUN wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
 && tar -C /usr/local/ -xzf go${GO_VERSION}.linux-amd64.tar.gz

# --- Compile go program ------------------------------------------------------

ARG PROGRAM_NAME="unknown"
ARG BUILD_VERSION=0.0.0
ARG BUILD_ITERATION=0
ARG GO_PACKAGE_NAME="unknown"

ENV HOME="/root"
ENV GOPATH="${HOME}/go"
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"

# Copy local files from the Git repository.

COPY . ${GOPATH}/src/${GO_PACKAGE_NAME}

# Build go program.

WORKDIR ${GOPATH}/src/${GO_PACKAGE_NAME}

RUN mkdir ~/.ssh \
 && touch ~/.ssh/known_hosts \
 && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Create Linux binary.

RUN make build

# Copy binaries to output.

RUN mkdir -p /output \
 && cp -R ${GOPATH}/src/${GO_PACKAGE_NAME}/target/*  /output/

# --- Test go program ---------------------------------------------------------

# Run unit tests.

# RUN go get github.com/jstemmer/go-junit-report \
#  && mkdir -p /output/go-junit-report \
#  && go test -v ${GO_PACKAGE_NAME}/... | go-junit-report > /output/go-junit-report/test-report.xml

# --- Package as RPM and DEB --------------------------------------------------

# RPM package.

RUN fpm \
  --input-type dir \
  --output-type rpm \
  --name ${PROGRAM_NAME} \
  --package /output/linux \
  --version ${BUILD_VERSION} \
  --iteration ${BUILD_ITERATION} \
  /output/linux/go-hello-cobra=/usr/bin/go-hello-cobra


# DEB package.

RUN fpm \
  --input-type dir \
  --output-type deb \
  --name ${PROGRAM_NAME} \
  --package /output/linux \
  --version ${BUILD_VERSION} \
  --iteration ${BUILD_ITERATION} \
  /output/linux/go-hello-cobra=/usr/bin/go-hello-cobra


# --- Epilog ------------------------------------------------------------------

RUN yum clean all

CMD ["/bin/bash"]
