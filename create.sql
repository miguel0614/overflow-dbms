BEGIN;
CREATE TABLE badges (
	badge_id SERIAL PRIMARY KEY,
	user_id INTEGER NOT NULL,
	class SMALLINT NOT NULL,
	name VARCHAR(256) NOT NULL,
	tag_based BOOLEAN NOT NULL,
	date TIMESTAMP NOT NULL
);

CREATE TABLE comments (
	comment_id SERIAL PRIMARY KEY,
	post_id INTEGER NOT NULL,
	user_id INTEGER,
	score SMALLINT DEFAULT 0,
	content_license VARCHAR(64) NOT NULL,
	text TEXT,
	creation_date TIMESTAMP NOT NULL
);

CREATE TABLE history (
	history_id SERIAL PRIMARY KEY,
	post_id INTEGER NOT NULL,
	user_id INTEGER,
	post_history_type_id SMALLINT NOT NULL,
	content_license VARCHAR(64),
	revision_guid uuid,
	text TEXT,
	comment TEXT,
	creation_date TIMESTAMP NOT NULL
);

CREATE TABLE links (
	link_id SERIAL PRIMARY KEY,
	related_post_id INTEGER NOT NULL,
	post_id INTEGER NOT NULL,
	link_type_id SMALLINT NOT NULL,
	creation_date TIMESTAMP NOT NULL
);

CREATE TABLE posts (
	post_id SERIAL PRIMARY KEY,
	owner_user_id INTEGER,
	last_editor_user_id INTEGER,
	post_type_id SMALLINT,
	accepted_answer_id INTEGER,
	score INTEGER DEFAULT 0,
	parent_id INTEGER,
	view_count INTEGER,
	answer_count INTEGER DEFAULT 0,
	comment_count INTEGER DEFAULT 0,
	title VARCHAR(512),
	tags VARCHAR(512),
	content_license VARCHAR(64),
	body TEXT,
	favorite_count INTEGER,
	creation_date TIMESTAMP,
	community_owned_date TIMESTAMP,
	closed_date TIMESTAMP,
	last_edit_date TIMESTAMP,
	last_activity_date TIMESTAMP
);

CREATE TABLE tags (
	tag_id SERIAL PRIMARY KEY,
	excerpt_post_id INTEGER,
	wiki_post_id INTEGER,
	tag_name VARCHAR(256) NOT NULL,
	count INTEGER DEFAULT 0
);

CREATE TABLE users (
	user_id SERIAL PRIMARY KEY,
	account_id INTEGER,
	reputation INTEGER NOT NULL DEFAULT 0,
	views INTEGER DEFAULT 0,
	down_votes INTEGER DEFAULT 0,
	up_votes INTEGER DEFAULT 0,
	display_name VARCHAR(256) NOT NULL,
	location VARCHAR(512),
	profile_image_url VARCHAR(256),
	website_url VARCHAR(256),
	about_me TEXT,
	creation_date TIMESTAMP NOT NULL,
	last_access_date TIMESTAMP NOT NULL
);

CREATE TABLE votes (
	vote_id SERIAL PRIMARY KEY,
	user_id INTEGER,
	post_id INTEGER NOT NULL,
	vote_type_id SMALLINT NOT NULL,
	bounty_amount SMALLINT DEFAULT 0,
	creation_date TIMESTAMP NOT NULL
);
COMMIT;

BEGIN;
ALTER TABLE badges
ADD FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE comments
ADD FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE history
ADD FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE links
ADD FOREIGN KEY (post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (related_post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE posts
ADD FOREIGN KEY (owner_user_id) REFERENCES users(user_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (parent_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE tags
ADD FOREIGN KEY (excerpt_post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (wiki_post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE votes
ADD FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE SET NULL
ON UPDATE CASCADE,
ADD FOREIGN KEY (post_id) REFERENCES posts(post_id)
ON DELETE SET NULL
ON UPDATE CASCADE;
COMMIT;