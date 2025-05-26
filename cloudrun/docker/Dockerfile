# Build stage
FROM dart:stable AS build

WORKDIR /read_firestore_app

# Copy only pubspec files first for better layer caching
COPY ./read_firestore/pubspec.* ./

# Install dependencies
RUN dart pub get

# Copy app source code (except anything in .dockerignore)
COPY ./read_firestore .

# Build the executable
RUN dart compile exe bin/read_firestore.dart -o /bin/read_firestore.exe

# Build minimal image from AOT-compiled `read_firestore.exe` and the 
# pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /read_firestore_app/bin/read_firestore.exe /

# Command to run the application
CMD ["/read_firestore.exe -p tindart-8c83b -c images"]