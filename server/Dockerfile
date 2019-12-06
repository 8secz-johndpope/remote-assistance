FROM alpine/node

COPY . /app
WORKDIR /app

RUN rm -rf .build-deps \
    && apk add --no-cache --virtual .build-deps make gcc g++ python \
    && npm install --production --silent \
    && apk del .build-deps \
    && rm -rf .build-deps

EXPOSE 5000
EXPOSE 5443
CMD ["node", "index.js"]
