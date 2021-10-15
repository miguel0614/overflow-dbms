BEGIN;
COPY users(user_id, account_id, reputation, views, down_votes, up_votes, display_name, location, profile_image_url, website_url, about_me, creation_date, last_access_date) 
FROM
   'C:\temp\users.csv' DELIMITER ',' CSV NULL '' ;

COPY posts( post_id, owner_user_id, last_editor_user_id, post_type_id, accepted_answer_id, score, parent_id, view_count, answer_count, comment_count, title, tags, content_license, body, favorite_count, creation_date, community_owned_date, closed_date, last_edit_date, last_activity_date) 
FROM
   'C:\temp\posts.csv' DELIMITER  ',' CSV NULL '' ;

COPY tags(tag_id, excerpt_post_id, wiki_post_id, tag_name, count) 
FROM
   'C:\temp\tags.csv' DELIMITER  ',' CSV NULL '' ;

COPY votes( vote_id, user_id, post_id, vote_type_id, bounty_amount, creation_date) 
FROM
   'C:\temp\votes.csv' DELIMITER  ',' CSV NULL '' ;

COPY links( link_id, related_post_id, post_id, link_type_id, creation_date) 
FROM
   'C:\temp\links.csv' DELIMITER  ',' CSV NULL '' ;

COPY history( history_id, post_id, user_id, post_history_type_id, content_license, revision_guid, text, comment, creation_date) 
FROM
   'C:\temp\history.csv' DELIMITER  ',' CSV NULL '' ;

COPY comments( comment_id, post_id, user_id, score, content_license, text, creation_date) 
FROM
   'C:\temp\comments.csv' DELIMITER  ',' CSV NULL '' ;

COPY badges( badge_id, user_id, class, name, tag_based, date) 
FROM
   'C:\temp\badges.csv' DELIMITER  ',' CSV NULL '' ;
COMMIT;