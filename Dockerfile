FROM alpine:3.15

RUN apk update && \
    apk add --no-cache openssl

WORKDIR app

COPY generate.sh .
RUN chmod +x generate.sh

CMD ["/app/generate.sh"]
