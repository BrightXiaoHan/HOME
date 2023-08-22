ARG VERSION=latest
FROM ubuntu:$VERSION

ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ENV http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY

# Change timezone to Shanghai
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -y tzdata python3 python3-pip curl fuse git \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/.HOME
ADD . .
RUN bash ./scripts/install.sh

ENV http_proxy="" https_proxy=""

ENV PATH="/root/.cache/homecli/miniconda/bin:${PATH}"

WORKDIR /workspace
VOLUME ["/workplace"]

CMD ["fish"]
