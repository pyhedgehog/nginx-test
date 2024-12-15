FROM nginx:1.27.3
USER 0
ENV DEBUG=1
COPY --chmod=555 nginx-test.sh /usr/local/bin/
RUN rm -rf /etc/nginx
ENTRYPOINT ["/usr/local/bin/nginx-test.sh"]
