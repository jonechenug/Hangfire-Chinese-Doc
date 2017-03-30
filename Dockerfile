FROM nginx
RUN apt-get update && \
    apt-get install -y --force-yes -m  python-sphinx make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ARG source=.
WORKDIR /app
COPY $source .
RUN make html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
