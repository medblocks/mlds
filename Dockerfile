ARG HERMES_VERSION=v0.8.4--alpha

FROM google/cloud-sdk:363.0.0-alpine as gsutils
ARG GCS_LOCATION
ARG HERMES_VERSION
RUN mkdir -p /src/downloads/extracts
WORKDIR /src/downloads
# Download SNOMED files from GCS
RUN gsutil cp -r $GCS_LOCATION .
# Unzip the files
RUN for i in *.zip; do unzip "$i" -d "./extracts/${i%%.zip}"; done
RUN wget -O hermes.jar https://github.com/wardle/hermes/releases/download/${HERMES_VERSION}/hermes-${HERMES_VERSION}.jar 


FROM openjdk:11-jre-slim as indexer
RUN mkdir -p /src
WORKDIR /src
COPY --from=gsutils /src/downloads/extracts ./extracts
COPY --from=gsutils /src/downloads/hermes.jar ./hermes.jar
RUN java -jar hermes.jar -d ./snomed.db import ./extracts
RUN java -jar hermes.jar -d ./snomed.db index
RUN java -Xmx8g -jar hermes.jar -d ./snomed.db compact

FROM openjdk:11-jre-slim
COPY --from=gsutils /src/downloads/hermes.jar /app/hermes.jar
COPY --from=indexer /src/snomed.db /app/snomed.db
WORKDIR /app
CMD ["java", "-jar", "hermes.jar", "-a", "0.0.0.0", "-d", "snomed.db", "-p", "8080", "--allowed-origins", "*", "serve"]
