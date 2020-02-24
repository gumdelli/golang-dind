FROM golang:1.12.7-stretch

RUN apt-get update && \
    apt-get install -y \
            unzip \
            postgresql-client \
            openssh-client \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg2 \
            software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository \
                       "deb [arch=amd64] https://download.docker.com/linux/debian \
                       $(lsb_release -cs) \
                       stable" && \
    apt-get update && \
    apt-get install -y \
            docker-ce \
            docker-ce-cli \
            containerd.io

COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/modprobe
RUN chmod +x /usr/local/bin/docker-entrypoint.sh


RUN ln -sf bash /bin/sh

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.2
RUN curl -fsS "https://releases.hashicorp.com/vault/0.10.4/vault_0.10.4_linux_amd64.zip" | funzip > /bin/vault && chmod +x /bin/vault
RUN echo -e '\n. ~/.asdf/asdf.sh' >> ~/.bashrc && \
        echo -e '\n. ~/.asdf/completions/asdf.bash' >> ~/.bashrc && source ~/.bashrc && \
        asdf plugin-add yq https://github.com/paxosglobal/asdf-yq.git && \
        asdf plugin-add jq https://github.com/paxosglobal/asdf-jq.git
RUN curl -fsS "https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip" | funzip > /bin/terraform && chmod +x /bin/terraform

RUN mkdir -p ~/.ssh
RUN touch ~/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> ~/.ssh/known_hosts





# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sh"]

