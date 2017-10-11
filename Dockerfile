# Jenkins comes with JDK8
FROM openjdk:8-jdk-alpine

# Set desired Node JS version
ENV NODE_VERSION    8.6.0
ENV SDK_VERSION     25.2.3
ENV SDK_CHECKSUM    1b35bcb94e9a686dff6460c8bca903aa0281c6696001067f34ec00093145b560
ENV ANDROID_HOME    /opt/android-sdk
ENV SDK_UPDATE      tools,platform-tools,platform-tools,android-23,build-tools-23.0.3,android-24,build-tools-24.0.1
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/tools/lib64/qt:${ANDROID_HOME}/tools/lib/libQt5:$LD_LIBRARY_PATH/
ENV GRADLE_VERSION  3.0
ENV GRADLE_HOME     /opt/gradle-${GRADLE_VERSION}
ENV PATH            ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${GRADLE_HOME}/bin

RUN apk add --no-cache curl \
    && curl -SLO "https://dl.google.com/android/repository/tools_r${SDK_VERSION}-linux.zip" \
    && echo "${SDK_CHECKSUM}  tools_r${SDK_VERSION}-linux.zip" | sha256sum -cs \
    && mkdir -p "${ANDROID_HOME}" \
    && unzip "tools_r${SDK_VERSION}-linux.zip" -d "${ANDROID_HOME}" \
    && rm -Rf "tools_r${SDK_VERSION}-linux.zip" \
    && echo y | ${ANDROID_HOME}/tools/android update sdk --filter ${SDK_UPDATE} --all --no-ui --force \
    && mkdir -p ${ANDROID_HOME}/tools/keymaps \
    && touch ${ANDROID_HOME}/tools/keymaps/en-us \
    # Licenses taken from https://github.com/mindrunner/docker-android-sdk
    && mkdir -p ${ANDROID_HOME}/licenses \
    && echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55\n" > ${ANDROID_HOME}/licenses/android-sdk-license \
    && echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd\n" > ${ANDROID_HOME}/licenses/android-sdk-preview-license \
    # Install gradle
    && curl -SLO https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && mkdir -p "${GRADLE_HOME}" \
    && unzip "gradle-${GRADLE_VERSION}-bin.zip" -d "/opt" \
    && rm -f "gradle-${GRADLE_VERSION}-bin.zip" \
    && apk del curl

# install node
RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
  # gpg keys listed at https://github.com/nodejs/node#release-team
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

ENV YARN_VERSION 1.1.0

RUN apk add --no-cache --virtual .build-deps-yarn curl gnupg tar \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt/yarn \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && apk del .build-deps-yarn
  
# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV PROJECT /project
RUN mkdir $PROJECT
WORKDIR $PROJECT
