FROM python:3.8 as python
RUN mkdir -p /src
WORKDIR /src
COPY requirements.txt .
ARG username
ARG password
ENV MLDS_DOWNLOAD_USERNAME=$username
ENV MLDS_DOWNLOAD_PASSWORD=$password
RUN "pip install -r requirements.txt"
RUN "python main.py dowload releases.txt"
RUN "python main.py extract"

FROM openjdk:8 as indexer
RUN mkdir -p /src
WORKDIR /src
COPY --from=python /src/downloads/extracts ./extracts
# Auto download from releaes using curl
COPY ./hermes-v0.6.2.jar ./hermes.jar
RUN "java -jar hermes.jar -d ./snomed.db import ./extracts"
RUN "java -jar hermes.jar -d ./snomed.db index"
RUN "java -Xmx8g -jar hermes.jar -d ./snomed.db compact"

FROM openjdk:8
RUN mkdir -p /src
WORKDIR /src
COPY ./hermes-v0.6.2.jar ./
COPY --from=indexer /src/snomed.db ./snomed.db
CMD ["java", "-jar", "/src/hermes.jar", "-d", "/src/snomed.db", "-p", "8080", "serve"]