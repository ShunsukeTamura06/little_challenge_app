-- 1. カテゴリのマスターテーブル
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- 2. 挑戦（チャレンジ）のマスターテーブル
CREATE TABLE challenges (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    difficulty SMALLINT NOT NULL CHECK (difficulty BETWEEN 1 AND 5)
);


-- ユーザー情報を格納するテーブル（IDをTEXT型に修正）
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    apple_user_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ユーザーが選択したカテゴリを保存するテーブル（user_idをTEXT型に修正）
CREATE TABLE user_category_preferences (
    user_id TEXT NOT NULL REFERENCES users(id),
    category_id INTEGER NOT NULL REFERENCES categories(id),
    PRIMARY KEY (user_id, category_id)
);

-- ユーザーの達成記録を格納するテーブル（user_idをTEXT型に修正）
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    challenge_id INTEGER NOT NULL REFERENCES challenges(id),
    memo TEXT,
    photo_url TEXT,
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);