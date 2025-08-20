-- 1. カテゴリのマスターテーブル
-- 「食事」「運動」などのカテゴリ情報を格納します。
CREATE TABLE categories (
    id SERIAL PRIMARY KEY, -- 自動で番号が振られる主キー
    name VARCHAR(50) UNIQUE NOT NULL, -- カテゴリ名（例: 食事）
    description TEXT -- カテゴリの説明
);

-- 2. 挑戦（チャレンジ）のマスターテーブル
-- LLMに生成させた挑戦のリストを格納します。
CREATE TABLE challenges (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id), -- categoriesテーブルへの参照
    title VARCHAR(255) NOT NULL, -- 挑戦のタイトル
    description TEXT NOT NULL, -- 挑戦の詳細な説明
    difficulty SMALLINT NOT NULL CHECK (difficulty BETWEEN 1 AND 5) -- 難易度（1から5）
);

-- 3. ユーザー情報を格納するテーブル
CREATE TABLE users (
    id UUID PRIMARY KEY, -- ユーザーを一意に識別するID
    apple_user_id TEXT UNIQUE NOT NULL, -- Sign in with Appleから取得するID
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- 登録日時
);

-- 4. ユーザーが選択したカテゴリを保存するテーブル（中間テーブル）
CREATE TABLE user_category_preferences (
    user_id UUID NOT NULL REFERENCES users(id),
    category_id INTEGER NOT NULL REFERENCES categories(id),
    PRIMARY KEY (user_id, category_id) -- ユーザーIDとカテゴリIDの組み合わせが重複しないようにする
);

-- 5. ユーザーの達成記録を格納するテーブル
CREATE TABLE achievements (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    challenge_id INTEGER NOT NULL REFERENCES challenges(id),
    memo TEXT, -- ユーザーが残したメモ
    photo_url TEXT, -- アップロードされた写真のURL
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5), -- 5段階評価
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT now() -- 達成日時
);

-- 6. ユーザーがストックしたチャレンジを格納するテーブル
CREATE TABLE stocks (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    challenge_id INTEGER NOT NULL REFERENCES challenges(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- ストック作成日時
    UNIQUE (user_id, challenge_id) -- 同じチャレンジを重複してストックしないようにする
);