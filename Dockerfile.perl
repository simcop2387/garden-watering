FROM perl:latest

COPY cpanfile cpanfile
RUN cpanm --verbose --installdeps .
