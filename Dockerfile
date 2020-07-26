FROM golang:1.11.2-alpine3.8 as builder
ADD . /go/src/git.com/cnb0/cnative.cicd
WORKDIR /go/src/github.com/cnb0/cnative.cicd/cmd
ARG VERSION
RUN go build -ldflags "-X main.version=$VERSION" -o book-server

FROM alpine:3.8 as production
COPY --from=builder /go/src/github.com/cnb0/cnative.cicd/cmd/book-server /book-server
ENTRYPOINT ["/book-server"]
