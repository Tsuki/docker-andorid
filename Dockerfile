# Jenkins comes with JDK8
FROM openjdk:8-jdk-alpine

# Set desired Android Linux SDK version
ENV ANDROID_SDK_VERSION 24.4.1

ENV ANDROID_SDK_ZIP android-sdk_r$ANDROID_SDK_VERSION-linux.tgz
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/$ANDROID_SDK_ZIP
ENV ANDROID_HOME /opt/android-sdk-linux

ENV GRADLE_ZIP gradle-3.0-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:/opt/gradle-3.0/bin

USER root

# Init dependencies for the setup process
RUN dpkg --add-architecture i386
RUN apt-get update && \
	apt-get install software-properties-common unzip -y

# Install gradle
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && \
	rm /opt/$GRADLE_ZIP

# Install Android SDK
# ADD $ANDROID_SDK_ZIP_URL /opt/
RUN wget $ANDROID_SDK_ZIP_URL -P /opt/ && \
	tar xzvf /opt/$ANDROID_SDK_ZIP -C /opt/ && \
	rm /opt/$ANDROID_SDK_ZIP

# Install required build-tools
RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-23,build-tools-23.0.3 && \
	chmod -R 777 $ANDROID_HOME

RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-24,build-tools-24.0.1 && \
	chmod -R 777 $ANDROID_HOME

# Install 32-bit compatibility for 64-bit environments
RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

# Create the license folder
RUN mkdir "$ANDROID_HOME/licenses" || true
RUN echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license"
RUN echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV PROJECT /project
RUN mkdir $PROJECT
WORKDIR $PROJECT
