ARG BASE_IMAGE=ubuntu
ARG VERSION=latest
FROM ${BASE_IMAGE}:${VERSION}

ARG HTTPS_PROXY=""
ENV https_proxy=$HTTPS_PROXY

# Change timezone to Shanghai
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -y tzdata python3 python3-pip curl fuse git \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/HOME
ADD . .
RUN bash ./scripts/install.sh -m local-install
RUN ln -s /root/.homecli/miniconda/bin/fish /usr/bin/fish

ENV https_proxy=""

WORKDIR /workspace

ENTRYPOINT ["fish"]

CMD ["-c", "kimi login && kimi --web"]