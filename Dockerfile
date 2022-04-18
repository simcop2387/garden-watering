FROM debian-slim:latest

RUN apt update && apt install openssh-client
