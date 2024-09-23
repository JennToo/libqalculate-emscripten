FROM emscripten/emsdk:3.1.67

RUN apt-get update && apt-get install -y m4 intltool pkg-config
