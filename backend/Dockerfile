# 公式のPythonランタイムを親イメージとして使用
FROM python:3.11-slim

# コンテナ内のワーキングディレクトリを設定
WORKDIR /app

# 高速なPythonパッケージマネージャであるuvをインストール
RUN pip install uv

# 依存関係ファイルをコピー
COPY ./requirements.txt /app/requirements.txt

# uvを使ってrequirements.txtから依存関係をインストール
# --systemフラグを追加して、コンテナのシステムPythonにインストールすることを許可
RUN uv pip install --system --no-cache -r /app/requirements.txt

# アプリケーションコードの残りをコンテナにコピー
COPY . /app

# アプリを実行。「0.0.0.0」でコンテナ外部からアクセスできるようにする
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]