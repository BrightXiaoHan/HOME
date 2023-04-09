ARG VERSION=latest
FROM ubuntu:$VERSION

ENV HTTP_PROXY ""
ENV HTTPS_PROXY ""

# Change timezone to Shanghai
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -y tzdata python3 python3-pip curl \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Prepare python environment
RUN pip install --no-cache-dir -i https://pypi.douban.com/simple poetry black isort mypy

WORKDIR /root/.HOME
ADD . .
RUN bash ./scripts/install.sh

RUN homecli

ENTRYPOINT ["/bin/bash"]
