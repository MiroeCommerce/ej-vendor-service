# Dockerfile for a Standalone Service Build

# --- STAGE 1: The Build Environment ---
FROM --platform=linux/arm64 almalinux:latest AS build

# --- Install Build Tools ---
RUN dnf install -y wget unzip tar

# --- Install OpenJDK 21 for ARM64 ---
RUN wget https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-aarch64_bin.tar.gz
RUN tar -xvf openjdk-21.0.2_linux-aarch64_bin.tar.gz -C /opt
ENV JAVA_HOME=/opt/jdk-21.0.2
ENV PATH=$JAVA_HOME/bin:$PATH

# --- Install Latest Gradle ---
RUN wget https://services.gradle.org/distributions/gradle-8.8-bin.zip
RUN mkdir /opt/gradle && unzip -d /opt/gradle gradle-8.8-bin.zip
ENV GRADLE_HOME=/opt/gradle/gradle-8.8
ENV PATH=$GRADLE_HOME/bin:$PATH

WORKDIR /app

# Copy only the contents of the current directory (the service folder)
COPY . .

# Make the Gradle wrapper script executable
RUN chmod +x ./gradlew

# CORRECTED: Execute the build command for the project in the current directory.
RUN ./gradlew bootJar -x test --stacktrace


# --- STAGE 2: The Final Runtime Environment ---
FROM openjdk:21-slim

WORKDIR /app

# Copy the JAR from the build directory.
COPY --from=build /app/build/libs/*.jar app.jar

# --- IMPORTANT ---
# This port MUST match the 'server.port' in this service's application.properties.
EXPOSE 8008

# The command to run the application when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
