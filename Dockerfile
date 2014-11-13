# Atom Docker Image For Package Testing
FROM ubuntu:trusty
MAINTAINER Joe Fitzgerald <jfitzgerald@pivotal.io>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ADD . $HOME

# Make Sure We're Up To Date
RUN sudo apt-get update
RUN sudo apt-get dist-upgrade -y

# Install Required Packages For Atom
RUN sudo apt-get install git gconf2 gconf-service libgtk2.0-0 libudev1 libgcrypt11 libgnome-keyring0 gir1.2-gnomekeyring-1.0 libnotify4 libxtst6 libnss3 gvfs-bin python xdg-utils libcap2 xvfb wget bzr git mercurial -y

# Start Xvfb
ENV DISPLAY :99.0
RUN start-stop-daemon --start --pidfile /tmp/xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -screen 0 1024x768x24 -ac +extension GLX +extension RANDR +render -noreset
RUN sleep 3

# Download And Install Atom
RUN wget -O atom-amd64.deb https://atom.io/download/deb
RUN sudo dpkg -i atom-amd64.deb
RUN sudo apt-get install -f
RUN rm -rf atom-amd64.deb
RUN apm --version

# Install Package Dependencies
RUN cd $HOME && apm install

# Download And Install Go
ENV GOLANG_VERSION 1.3.3
RUN wget -O go.tar.gz https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go.tar.gz
RUN rm -rf go.tar.gz
RUN mkdir $HOME/go
ENV GOPATH $HOME/go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
RUN env

# Download Go Tools
RUN go get -u github.com/golang/lint/golint
RUN sudo GOPATH=/tmp/tempGOPATH /usr/local/go/bin/go get -u golang.org/x/tools/cmd/cover
RUN go get -u golang.org/x/tools/cmd/goimports
RUN sudo GOPATH=/tmp/tempGOPATH /usr/local/go/bin/go get -u golang.org/x/tools/cmd/vet
RUN sudo rm -rf /tmp/tempGOPATH
RUN go get -u sourcegraph.com/sqs/goreturns

# Run Package Specs
RUN cd $HOME && apm test
