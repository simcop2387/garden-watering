FROM debian:stable-slim

RUN apt update && apt install -y openssh-client
