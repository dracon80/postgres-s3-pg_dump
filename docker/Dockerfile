ARG ENVIRONMENT="production"

########################################################
# Dependency Builder Image
########################################################
FROM debian:bookworm as installer
# Install AWS Commandline
RUN apt-get update && apt-get install curl unzip -y && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /aws-cli-bin

#Download postgres repository signature
RUN curl -o /etc/apt/trusted.gpg.d/apt-postgresql.acs --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN echo "Types: deb" > /etc/apt/sources.list.d/postgresql.sources && \
    echo "#https://www.postgresql.org/media/keys/ACCC4CF8.asc" >> /etc/apt/sources.list.d/postgresql.sources && \
    echo "URIs: https://apt.postgresql.org/pub/repos/apt" >> /etc/apt/sources.list.d/postgresql.sources && \
    echo "Suites: bookworm-pgdg" >> /etc/apt/sources.list.d/postgresql.sources && \
    echo "Components: main" >> /etc/apt/sources.list.d/postgresql.sources && \
    echo "Signed-By: /etc/apt/trusted.gpg.d/apt-postgresql.acs" >> /etc/apt/sources.list.d/postgresql.sources


########################################################
# Dependency Builder Image
########################################################
FROM debian:bookworm as postgresql-s3-backup

#install basic requirements
RUN apt-get update && apt-get install mandoc less ca-certificates unzip aespipe -y

COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer /etc/apt/trusted.gpg.d/apt-postgresql.acs /etc/apt/trusted.gpg.d/apt-postgresql.acs
COPY --from=installer /etc/apt/sources.list.d/postgresql.sources /etc/apt/sources.list.d/postgresql.sources

#install postgres client
RUN apt-get update && apt-get install postgresql-client-16 -y

#create the backup user and set workdir
RUN useradd s3backup -d /backup -s /bin/nologin
USER s3backup:s3backup
WORKDIR /backup
RUN touch .pgpass && chmod 0600 .pgpass

#ENTRYPOINT ["/usr/local/bin/aws"]