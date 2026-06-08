FROM codercom/code-server
USER root
RUN apt update -y
RUN apt upgrade -y
WORKDIR /root
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN sh get-docker.sh
RUN adduser coder docker
RUN apt install -y makepasswd
RUN code-server --install-extension ms-azuretools.vscode-docker
COPY /entrypoint.sh /
RUN chmod +x /entrypoint.sh
WORKDIR /root/.local/share/code-server/User
COPY /settings.json ./
WORKDIR /
COPY /examples/ /examples/
COPY /.code-workspace /
ENTRYPOINT ["/entrypoint.sh"]
CMD []
