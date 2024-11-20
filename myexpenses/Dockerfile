FROM node:20-alpine
RUN apk add --no-cache bash
RUN mkdir -p /opt/server
RUN adduser -D -h /opt/server expense
RUN chown -R expense:expense /opt/server
WORKDIR /opt/server
COPY package.json ./
RUN npm install --production
COPY src/ ./src
COPY public/ ./public
RUN chown -R expense:expense /opt/server/node_modules
USER expense
EXPOSE 3000
CMD ["npm", "start"]
