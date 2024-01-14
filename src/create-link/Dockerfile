FROM alpine:latest

RUN apk add gettext openssh-client wireguard-tools python3;

COPY . /code

WORKDIR /code

ENV LINK_MTU=1380

ENTRYPOINT ["/code/entrypoint.sh"]
