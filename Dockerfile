FROM python:3 as python
RUN mkdir -p /src
WORKDIR /src
COPY ./requirements.txt .
RUN pip install -r /src/requirements.txt
COPY . .
ARG username
ARG password
ENV MLDS_DOWNLOAD_USERNAME=$username
ENV MLDS_DOWNLOAD_PASSWORD=$password
RUN python main.py download packages.txt
RUN python main.py extract

FROM openjdk:11-jre-slim as indexer
RUN mkdir -p /src
WORKDIR /src
COPY --from=python /src/downloads/extracts ./extracts
# Auto download from releaes using curl
COPY ./hermes-v0.8.1.jar ./hermes.jar
RUN java -jar hermes.jar -d ./snomed.db import ./extracts
RUN java -jar hermes.jar -d ./snomed.db index
# RUN java -Xmx8g -jar hermes.jar -d ./snomed.db compact

FROM openjdk:11-jre-slim
RUN mkdir -p /src
WORKDIR /src
COPY ./hermes-v0.8.1.jar ./hermes.jar
COPY --from=indexer /src/snomed.db ./snomed.db
CMD ["java", "-jar", "/src/hermes.jar", "-a", "0.0.0.0", "-d", "/src/snomed.db", "-p", "8080", "serve"]