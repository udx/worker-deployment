# Use UDX Worker as the base image
FROM {{BASE_IMAGE}}

LABEL maintainer="UDX"

ENV APP_HOME="{{APP_HOME}}"

USER root
RUN mkdir -p "{{APP_HOME}}" && \
    chown -R "${USER}:${USER}" "{{APP_HOME}}" && \
    chmod -R 755 "{{APP_HOME}}"

USER "${USER}"
WORKDIR "{{APP_HOME}}"

# Use the parent image's entrypoint
ENTRYPOINT ["/usr/local/worker/bin/entrypoint.sh"]

# Default command (override in your runtime)
CMD ["tail", "-f", "/dev/null"]
