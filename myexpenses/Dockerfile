FROM node:20-alpine
RUN apk add --no-cache bash
RUN mkdir /opt/server
RUN adduser -D -h /opt/server expense
RUN chown expense:expense -R /opt/server
WORKDIR /opt/server
COPY package.json ./
COPY src/ .
COPY public/ .
RUN npm install --production
USER expense
EXPOSE 3000
CMD ["sleep", "2000"]