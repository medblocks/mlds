ARG gs_location

FROM python:3 as gsutils
RUN mkdir -p /src/downloads/extracts
WORKDIR /src/downloads
RUN pip install gsutil && apt-get -y install --no-install-recommends unzip
# Download SNOMED files from GCS
RUN gsutil cp -r ${gs_location} .
# Unzip the files
RUN unzip \*.zip -d ./extracts; exit 0


FROM openjdk:11-jre-slim as indexer
RUN mkdir -p /src
WORKDIR /src
COPY --from=gsutils /src/downloads/extracts ./extracts
COPY ./hermes-v0.8.3.jar ./hermes.jar
RUN java -jar hermes.jar -d ./snomed.db import ./extracts
RUN java -jar hermes.jar -d ./snomed.db index

FROM openjdk:11-jre-slim
COPY ./hermes-v0.8.3.jar /app/hermes.jar
COPY --from=indexer /src/snomed.db /app/snomed.db
WORKDIR /app
CMD ["hermes.jar", "-a", "0.0.0.0", "-d", "snomed.db", "-p", "8080", "serve"]