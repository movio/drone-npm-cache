FROM node:16

COPY cacher.sh /usr/local/
RUN mkdir /cache && chmod 755 /usr/local/cacher.sh
VOLUME /cache

ENTRYPOINT ["/usr/local/cacher.sh"]
