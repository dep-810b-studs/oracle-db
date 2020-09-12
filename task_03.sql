CREATE TABLE dim_date (
    date_value   DATE NOT NULL,
    id           INTEGER NOT NULL
);

ALTER TABLE dim_date ADD CONSTRAINT publish_date_pk PRIMARY KEY ( id );

CREATE TABLE dim_tags (
    tag_id      INTEGER NOT NULL,
    tag_value   VARCHAR2(100 CHAR) NOT NULL
);

ALTER TABLE dim_tags ADD CONSTRAINT tags_pk PRIMARY KEY ( tag_id );

CREATE TABLE fact_tag_on_post (
    publish_date      DATE,
    fact_id           INTEGER NOT NULL,
    tag_id            INTEGER,
    dim_date_id       INTEGER NOT NULL,
    dim_tags_tag_id   INTEGER NOT NULL,
    view_count        INTEGER,
    score             INTEGER
);

ALTER TABLE fact_tag_on_post ADD CONSTRAINT fact_tag_on_post_pk PRIMARY KEY ( fact_id );

ALTER TABLE fact_tag_on_post
    ADD CONSTRAINT fact_tag_on_post_dim_date_fk FOREIGN KEY ( dim_date_id )
        REFERENCES dim_date ( id );

ALTER TABLE fact_tag_on_post
    ADD CONSTRAINT fact_tag_on_post_dim_tags_fk FOREIGN KEY ( dim_tags_tag_id )
        REFERENCES dim_tags ( tag_id );
