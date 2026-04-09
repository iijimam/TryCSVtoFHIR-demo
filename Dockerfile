ARG IMAGE=containers.intersystems.com/intersystems/irishealth:2026.1
FROM $IMAGE

USER root
WORKDIR /opt/src
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/src
USER ${ISC_PACKAGE_MGRUSER}

# ビルド中に実行したいスクリプトがあるファイルをコンテナにコピーしています
COPY iris.script .
COPY src .

# IRISを開始し、IRISにログインし、iris.scriptに記載のコマンドを実行しています
RUN iris start IRIS \
    && pip install -r requirements.txt --break-system-packages \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly 