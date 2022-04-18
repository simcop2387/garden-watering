FROM debian:slim

RUN apt update && apt install openssh-client
