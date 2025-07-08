ARG LINUX_IMAGE="ubuntu"
ARG LINUX_IMAGE_VERSION="20.04"


# Build stage
FROM --platform=$BUILDPLATFORM ${LINUX_IMAGE}:${LINUX_IMAGE_VERSION} AS build

ARG SPHERE_GIT="https://github.com/SphereServer/Source.git"

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies for build
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7" | tee -a /etc/apt/sources.list && \
    apt update --allow-insecure-repositories && \
    apt install -y --allow-unauthenticated \
        libmysqlclient-dev=5.7* git gcc g++ make && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /source
WORKDIR "/source"

# Clone and build
RUN git clone ${SPHERE_GIT}
WORKDIR "/source/Source"
RUN make NIGHTLY=1


# Release stage
FROM --platform=$BUILDPLATFORM ${LINUX_IMAGE}:${LINUX_IMAGE_VERSION} AS release

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies for runtime
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7" | tee -a /etc/apt/sources.list && \
    apt update --allow-insecure-repositories && \
    apt install -y --no-install-recommends --allow-unauthenticated -y \
        libmysqlclient-dev=5.7* && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /sphereserver
WORKDIR /sphereserver

COPY --from=build /source/Source/spheresvr /sphereserver/spheresvr
COPY --from=build /source/Source/src/sphereCrypt.ini /sphereserver/sphereCrypt.ini
COPY --from=build /source/Source/src/sphere.ini /sphereserver/sphere.ini

EXPOSE 2593

ENTRYPOINT ["./spheresvr"]