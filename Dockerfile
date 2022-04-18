FROM debian:stable-slim

RUN apt update && apt install openssh-client
