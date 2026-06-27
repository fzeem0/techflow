FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        bash \
        bats \
        ca-certificates \
        coreutils \
        curl \
        dnsutils \
        file \
        findutils \
        gawk \
        git \
        gzip \
        iproute2 \
        iputils-ping \
        less \
        lsof \
        nano \
        netcat-openbsd \
        net-tools \
        procps \
        python3 \
        sed \
        shellcheck \
        shfmt \
        tar \
        traceroute \
        tree \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 student \
    && useradd --uid 1000 --gid student --create-home --shell /bin/bash student \
    && mkdir -p /opt/techflow /workspace \
    && chown student:student /workspace

WORKDIR /opt/techflow
COPY --chown=root:root . /opt/techflow
COPY --chown=root:root docker/entrypoint.sh /usr/local/bin/techflow-entrypoint

RUN chmod 0755 \
        /usr/local/bin/techflow-entrypoint \
        /opt/techflow/bin/techflow \
        /opt/techflow/app/server.py \
        /opt/techflow/generators/generate_data.py \
        /opt/techflow/scripts/bash.sh \
        /opt/techflow/scripts/check_health \
        /opt/techflow/scripts/init_workspace.sh \
        /opt/techflow/scripts/log_report.sh \
        /opt/techflow/scripts/monitor.sh \
        /opt/techflow/scripts/render_markdown.py \
        /opt/techflow/scripts/setup.env.sh \
        /opt/techflow/scripts/start-app \
        /opt/techflow/scripts/stop-app \
        /opt/techflow/scripts/sync_workspace.sh \
        /opt/techflow/scripts/test \
        /opt/techflow/scripts/verify_mission.sh \
    && ln -s /opt/techflow/bin/techflow /usr/local/bin/techflow

ENV HOME=/home/student \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    TECHFLOW_HOME=/workspace \
    TECHFLOW_PROJECT_ROOT=/opt/techflow

USER student
WORKDIR /workspace

ENTRYPOINT ["techflow-entrypoint"]
CMD ["techflow"]
