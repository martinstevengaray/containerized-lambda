# syntax=docker/dockerfile:1

# ---- build stage: compile + package the app (no local JDK/Gradle needed) ----
FROM gradle:8-jdk21 AS build
WORKDIR /app
COPY settings.gradle build.gradle ./
RUN --mount=type=cache,target=/root/.gradle gradle --no-daemon dependencies
COPY src ./src
RUN --mount=type=cache,target=/root/.gradle gradle --no-daemon clean build

# ---- Lambda Web Adapter binary ----
FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 AS adapter

# ---- runtime stage: a plain JRE image, NOT an AWS Lambda base image ----
FROM amazoncorretto:21
# The adapter is loaded as a Lambda extension; the execution environment auto-starts it. It
# polls the Runtime API and forwards each invocation as HTTP to our server on $PORT.
COPY --from=adapter /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=8080
WORKDIR /app
COPY --from=build /app/build/dependency/ /app/lib/
COPY --from=build /app/build/libs/*.jar /app/app.jar
# Our own entrypoint: just run the web server. Nothing Lambda-specific here.
CMD ["java", "-jar", "/app/app.jar"]
