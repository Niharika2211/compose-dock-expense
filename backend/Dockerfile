FROM node:20-alpine
RUN apk add --no-cache bash
RUN mkdir /opt/server
RUN adduser -D -h /opt/server expense
RUN chown expense:expense -R /opt/server
WORKDIR /opt/server
COPY package.json ./
COPY *.js ./
RUN npm install --production
USER expense
EXPOSE 8080
CMD ["node", "index.js"]
