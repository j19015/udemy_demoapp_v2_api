# ベースイメージを指定する
# FROM ベースイメージ:タグ
FROM ruby:2.7.2-alpine

# Dockerfile内で使用する変数を定義
# app
ARG WORKDIR

# 環境変数を定義(Dockerfile, コンテナ参照可)
# Rails ENV["TZ"] => Asia/Tokyo
ENV RUNTIME_PACKAGES="linux-headers libxml2-dev make gcc libc-dev nodejs tzdata postgresql-dev postgresql git" \
    DEV_PACKAGES="build-base curl-dev" \
    # /app
    HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# ベースイメージに対してコマンドを実行する
# ${HOME} or $HOME => /app
RUN echo ${HOME}

# Dockerfile内で指定した命令を実行する ... RUN, COPY, ADD, ENTORYPOINT, CMD
# 作業ディレクトリを定義
# コンテナ/app/Railsアプリ
WORKDIR ${HOME}

# ホスト側(PC)のファイルをコンテナにコピー
# COPY コピー元(ホスト) コピー先(コンテナ)
# Gemfile* ... Gemfileから始まるファイルを全指定(Gemfile, Gemfile.look)
# コピー元(ホスト) ... Dockerfileがあるディレクトリ以下を指定(api) ../ NG
# コピー先(コンテナ) ... 絶対パス or 相対パス(./ ... 今いる(カレント)ディレクトリ)
COPY Gemfile* ./

    # apk ... Alpine Linuxのコマンド
    # apk update = パッケージの最新リストを取得
RUN bundle config set force_ruby_platform true && \
    apk update && \
    # apk upgrade = インストールパッケージを最新のものに
    apk upgrade && \
    # apk add = パッケージのインストールを実行
    # --no-cache = パッケージをキャッシュしない(Dockerイメージを軽量化)
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    # --virtual 名前(任意) = 仮想パッケージ
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    # Gemのインストールコマンド
    # -j4(jobs=4) = Gemインストールの高速化
    bundle install -j4 && \
    # パッケージを削除(Dockerイメージを軽量化)
    apk del build-dependencies

# . ... Dockerfileがあるディレクトリ全てのファイル(サブディレクトリも含む)
COPY . ./

# コンテナ内で実行したいコマンドを定義
# -b ... バインド。プロセスを指定したip(0.0.0.0)アドレスに紐付け(バインド)する
CMD ["rails", "server", "-b", "0.0.0.0"]

# ホスト(PC)       | コンテナ
# ブラウザ(外部)   | Rails
