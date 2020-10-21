FROM python:3.7-slim

MAINTAINER Synx <engineering@synx.co>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Synx Machine Learning Backend" \
      org.label-schema.description="Default platform stack for machine learning projects." \
      org.label-schema.url="https://synx.ai" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/synx-ai/galois" \
      org.label-schema.vendor="Synx" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

RUN set -ex; \
    apt-get update --assume-yes && \
    apt-get upgrade --assume-yes && \
        apt-get install -t buster \
            supervisor \
            git \
            openssl \
            gcc \
            make \
            g++ \
            libpq-dev \
            wget \
            nginx \
            mtail \
            default-libmysqlclient-dev \
                --assume-yes


RUN pip install --upgrade --no-cache-dir pip setuptools
RUN set -ex; \
        pip install --no-cache-dir \
            munch \
            numpy \
            pandas \
            cython \
            scikit-learn \
            matplotlib \
            pyyaml \
            unidecode \
            joblib


#
RUN set -ex; \
        pip install --no-cache-dir \
            mongoengine \
            celery \
            psycopg2 \
            sshtunnel \
            sqlalchemy \
            mysqlclient


#
RUN set -ex; \
        pip install --no-cache-dir \
            flask \
            flask-restful \
            flask-cors \
            requests \
            cherrypy \
            Flask-CORS \
            flask_sqlalchemy \
            flask_jwt_extended \
            passlib


#
ENV JAVA_VERSION jdk8u252-b09

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM="536bf397d98174b376da9ed49d2f659d65c7310318d8211444f4b7ba7c15e453"; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_aarch64_linux_hotspot_8u252b09.tar.gz"; \
         ;; \
       armhf|armv7l) \
         ESUM="5b401ad3c9b246281bd6df34b1abaf75e10e5cad9c6b26b55232b016e90e411a"; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_arm_linux_hotspot_8u252b09.tar.gz"; \
         ;; \
       ppc64el|ppc64le) \
         ESUM="55f0453b1d28812154138cf52b17b7acd93b9e55263f1f508f559795d31b2671"; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_ppc64le_linux_hotspot_8u252b09.tar.gz"; \
         ;; \
       s390x) \
         ESUM="db39932666c37718b1c3c62a1adb4f8e9c33258cf15a85ddf9b4d71199edfb1d"; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_s390x_linux_hotspot_8u252b09.tar.gz"; \
         ;; \
       amd64|x86_64) \
         ESUM="2b59b5282ff32bce7abba8ad6b9fde34c15a98f949ad8ae43e789bbd78fc8862"; \
         BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/${JAVA_VERSION}/OpenJDK8U-jdk_x64_linux_hotspot_8u252b09.tar.gz"; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    wget -O /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"

RUN wget -O- "http://downloads.lightbend.com/scala/2.11.12/scala-2.11.12.tgz" \
    | tar xzf - -C /usr/local --strip-components=1


ENV SPARK_VERSION=2.4.5
ENV HADOOP_VERSION=2.7

#COPY bde-spark.css /css/org/apache/spark/ui/static/timeline-view.css

RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

RUN set -ex; \
    pip install --no-cache-dir \
        pyspark \
        notebook \
        xgboost==0.81 \
        py-spy \
        modin[dask] \
        jupyterthemes \
        prefect \
        bokeh \
        supervisord-dependent-startup \
        annoy \
        texthero \
        numba \
        umap-learn \
        watchdog


#
RUN prefect backend server
RUN jt -t onedork -T -N -altp

ENV PYTHONUNBUFFERED=0

CMD ["python"]
