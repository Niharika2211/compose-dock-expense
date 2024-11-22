FROM nginx:latest

RUN rm -rf /usr/share/nginx/html/* \
    && rm -rf /etc/nginx/nginx.conf \
    && rm -rf /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf

COPY index.html /usr/share/nginx/html/
COPY static/ /usr/share/nginx/html/static
COPY asset-manifest.json /usr/share/nginx/html/
