FROM perl:latest

COPY cpanfile
RUN cpanm --verbose --installdeps .
