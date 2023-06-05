FROM rhel/els:8.2-23

ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=/go \
    VERSION="1.12"

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN yum install -y --setopt=tsflags=nodocs \
    bc diffutils file findutils gpgme git hostname lsof make rsync socat tar tree util-linux wget which zip \
    "go-toolset-$VERSION.*" goversioninfo openssl openssl-devel systemd-devel gpgme-devel libassuan-devel && \
    mkdir -p /go/src && \
    yum clean all -y

COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN /bin/bash -c 'GO_BIN_PATH=`which go`; mv $GO_BIN_PATH $GO_BIN_PATH.real; mv /tmp/go_wrapper.sh $GO_BIN_PATH; chmod +x $GO_BIN_PATH'
