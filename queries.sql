-- Index on Date for Posts and Comments
CREATE INDEX post_date_index ON posts USING BTREE (creation_date DESC NULLS LAST); -- Group by date ranges are frequently used
CREATE INDEX comments_date_index ON comments USING BTREE (creation_date DESC NULLS LAST); -- Group by date ranges are frequently used
CREATE INDEX votes_type_index ON votes USING BTREE (vote_type_id DESC NULLS LAST); -- Frequently filtering based on vote type

-- Post Engagement
WITH post_engagement AS ( -- CTE calculates the average engagement of a post (answers + comments)
  SELECT 
    SUM(total) total, 
    tag 
  FROM 
    (
		-- Number of answers to a question
      SELECT 
        COUNT(*) total, 
        PARENT_ID ID, 
        TRIM(
          TRAILING '>' 
          FROM 
            UNNEST(
              STRING_TO_ARRAY(
                TRIM(
                  LEADING '<' 
                  FROM 
                    COALESCE(TAGS, 'NO TAG')
                ), 
                '<'
              )
            )
        ) AS Tag 
      FROM 
        POSTS 
      WHERE 
        POST_TYPE_ID = 2 
      GROUP BY 
        PARENT_ID, 
        tag 
      UNION ALL 
      SELECT -- Account for questions with no answers
        0 total, 
        POST_ID ID, 
        TRIM(
          TRAILING '>' 
          FROM 
            UNNEST(
              STRING_TO_ARRAY(
                TRIM(
                  LEADING '<' 
                  FROM 
                    COALESCE(TAGS, 'NO TAG')
                ), 
                '<'
              )
            )
        ) AS Tag 
      FROM 
        POSTS 
      WHERE 
        POST_TYPE_ID = 1 
        AND body IS NOT NULL 
        AND POST_ID NOT IN (
          SELECT 
            PARENT_ID 
          FROM 
            POSTS 
          GROUP BY 
            PARENT_ID
        ) 
      GROUP BY 
        POST_ID, 
        tag 
      UNION ALL 
      SELECT  -- Comments on the question post
        COUNT(*) total, 
        POST_ID ID, 
        TRIM(
          TRAILING '>' 
          FROM 
            UNNEST(
              STRING_TO_ARRAY(
                TRIM(
                  LEADING '<' 
                  FROM 
                    COALESCE(TAGS, 'NO TAG')
                ), 
                '<'
              )
            )
        ) AS Tag 
      FROM 
        COMMENTS C 
        JOIN POSTS USING(POST_ID) 
      WHERE 
        POST_TYPE_ID = 1 
      GROUP BY 
        POST_ID, 
        tag 
      UNION ALL 
      SELECT -- Questions on the answers
        COUNT(*) total, 
        PARENT_ID ID, 
        TRIM(
          TRAILING '>' 
          FROM 
            UNNEST(
              STRING_TO_ARRAY(
                TRIM(
                  LEADING '<' 
                  FROM 
                    COALESCE(TAGS, 'NO TAG')
                ), 
                '<'
              )
            )
        ) AS Tag 
      FROM 
        COMMENTS C 
        JOIN POSTS USING(POST_ID) 
      WHERE 
        POST_TYPE_ID = 2 
      GROUP BY 
        PARENT_ID, 
        tag
    ) engagement 
  GROUP BY 
    engagement.ID, 
    tag
) 
SELECT 
  AVG(total) average_engagement, 
  tag 
FROM 
  post_engagement 
GROUP BY 
  tag 
HAVING 
  COUNT(*) > 200 
ORDER BY 
  1 DESC

-- Category Engagement (Split Tags)
SELECT 
  COUNT(*), 
  TRIM(
    TRAILING '>' 
    FROM 
      UNNEST(
        STRING_TO_ARRAY(
          TRIM(
            LEADING '<' 
            FROM 
              COALESCE(TAGS, 'NO TAG')
          ), 
          '<'
        )
      )
  ) AS Tag 
FROM 
  POSTS 
WHERE 
  body IS NOT NULL -- 
GROUP BY 
  Tag 
ORDER BY 
  1 DESC 

-- Insert New Post Procedure
  CREATE PROCEDURE insert_new_post(
    owner_user_id integer, 
    last_editor_user_id integer, 
    post_type_id smallint, 
    parent_id integer, 
    title character varying(512), 
    tags character varying(512), 
    content_license character varying(64), 
    body text, 
    community_owned_date timestamp without time zone
  ) LANGUAGE SQL AS $$ INSERT INTO posts 
VALUES 
  (
    nextval('posts_post_id_seq' :: regclass), 
    owner_user_id, 
    last_editor_user_id, 
    post_type_id, 
    NULL, 
    0, 
    parent_id, 
    0, 
    0, 
    0, 
    title, 
    tags, 
    content_license, 
    body, 
    0, 
    CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE, 
    community_owned_date, 
    NULL, 
    CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE, 
    CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE
  );
UPDATE 
  users 
SET 
  last_access_date = CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE 
WHERE 
  user_id = owner_user_id;
UPDATE 
  tags 
SET 
  count = count + 1 
WHERE 
  insert_new_post.tags :: VARCHAR LIKE '%<' || tag_name || '>%';
$$;

BEGIN;
SELECT * FROM users WHERE user_id = 1;
SELECT * FROM tags WHERE tag_name = 'ag.algebraic-geometry'
CALL insert_new_post(
	1::integer, 
    1::integer, 
    2::smallint, 
    NULL::integer, 
    'TEST'::varchar(512), 
    '<ag.algebraic-geometry>'::varchar(512), 
    NULL::varchar(64),
    'TEST'::TEXT, 
    NULL::timestamp without time zone
  );
  SELECT * FROM users WHERE user_id = 1;
  SELECT * FROM tags WHERE tag_name = 'ag.algebraic-geometry'
  SELECT * FROM posts ORDER BY post_id DESC LIMIT 1;
ROLLBACK;

-- Insert Votes Procedure
CREATE PROCEDURE insert_vote(
  user_id integer, post_id integer, vote_type_id smallint
) LANGUAGE SQL AS $$ INSERT INTO votes 
VALUES 
  (
    nextval('votes_vote_id_seq' :: regclass), 
    user_id, 
    post_id, 
    vote_type_id, 
    0, 
    CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE
  );
UPDATE 
  users u 
SET 
  up_votes = CASE WHEN insert_vote.vote_type_id = 2 THEN up_votes + 1 ELSE up_votes END, 
  down_votes = CASE WHEN insert_vote.vote_type_id = 3 THEN down_votes + 1 ELSE down_votes END 
FROM 
  posts p 
WHERE 
  p.post_id = insert_vote.post_id 
  AND u.user_id = p.owner_user_id 
  AND (
    insert_vote.vote_type_id = 2 
    OR insert_vote.vote_type_id = 3
  );
UPDATE 
  posts p 
SET 
  favorite_count = favorite_count + 1 
WHERE 
  p.post_id = insert_vote.post_id 
  AND insert_vote.vote_type_id = 5; 
  
  UPDATE 
  posts p 
SET 
  score = CASE WHEN insert_vote.vote_type_id = 2 THEN score + 1  WHEN insert_vote.vote_type_id = 3 THEN score - 1 ELSE score END 
WHERE 
  p.post_id = insert_vote.post_id 
  AND (insert_vote.vote_type_id = 2 OR insert_vote.vote_type_id = 3);
  
UPDATE 
  users u 
SET 
  last_access_date = CURRENT_TIMESTAMP(0):: TIMESTAMP WITHOUT TIME ZONE 
WHERE 
  u.user_id = insert_vote.user_id 
  AND insert_vote.user_id IS NOT NULL;
$$;


BEGIN;
SELECT * FROM users WHERE user_id = 1;
SELECT * FROM posts WHERE post_id = 1;
CALL insert_vote(
	1::integer,
	1::integer,
	3::smallint
);
  SELECT * FROM users WHERE user_id = 1;
  SELECT * FROM posts WHERE post_id = 1;
ROLLBACK;



-- Get Average Post Rating By Tag
Select 
  ROUND(
    AVG(avg_vote) * 100, 
    2
  ) percent_rating, 
  COUNT(*) post_count, 
  Tag 
FROM 
  (
    SELECT 
      AVG(
        CASE WHEN vote_type_id = 2 THEN 1.0 ELSE 0.0 END
      ) avg_vote, 
      TRIM(
        TRAILING '>' 
        FROM 
          UNNEST(
            STRING_TO_ARRAY(
              TRIM(
                LEADING '<' 
                FROM 
                  COALESCE(TAGS, 'NO TAG')
              ), 
              '<'
            )
          )
      ) AS Tag, 
      post_id 
    FROM 
      votes v 
      JOIN posts p USING(post_id) 
    WHERE 
      (
        vote_type_id = 2 
        OR vote_type_id = 3
      ) 
    GROUP BY 
      Tag, 
      post_id
  ) avg_post_ratings 
GROUP BY 
  Tag 
HAVING 
  COUNT(*) > 200 
ORDER BY 
  1 DESC 

-- Daily Post Count Queries
SELECT 
  COUNT(*), 
  creation_date :: date 
FROM 
  posts 
WHERE 
  creation_date IS NOT NULL 
GROUP BY 
  creation_date :: date 
ORDER BY 
  creation_date :: date DESC 

SELECT 
  COUNT(*), 
  creation_date :: date 
FROM 
  comments 
WHERE 
  creation_date IS NOT NULL 
GROUP BY 
  creation_date :: date 
ORDER BY 
  creation_date :: date DESC 
  
-- Weekly Post Count Queries 
SELECT 
  COUNT(*), 
  date_trunc('week', creation_date) week_start 
FROM 
  posts 
WHERE 
  creation_date IS NOT NULL 
GROUP BY 
  2 
ORDER BY 
  2 DESC
  
SELECT 
  COUNT(*), 
  date_trunc('week', creation_date) week_start 
FROM 
  comments 
WHERE 
  creation_date IS NOT NULL 
GROUP BY 
  2 
ORDER BY 
  2 DESC