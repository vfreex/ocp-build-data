FROM openshift/golang-builder@sha256:4b073c102097014a6a3a9c4a51637eb5c52508ee0d0d35c78a5a4736d3862e4f
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN /bin/bash -c 'GO_BIN_PATH=`which go`; mv $GO_BIN_PATH $GO_BIN_PATH.real; mv /tmp/go_wrapper.sh $GO_BIN_PATH; chmod +x $GO_BIN_PATH'
