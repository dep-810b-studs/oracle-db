drop table dim_date;
drop table FACT_TAG_ON_POST;
drop table dim_tags;

create sequence fact_tag_on_post_ids;
create sequence dim_tags_ids;

create table dim_date (
    date_value   date not null,
    id           integer not null
)
logging;

alter table dim_date add constraint publish_date_pk primary key ( id );

create table dim_tags (
    tag_id      integer not null,
    tag_value   varchar2(100 char) not null
)
logging;

alter table dim_tags add constraint tags_pk primary key ( tag_id );

create table fact_tag_on_post (
    fact_id           integer not null,
    tag_id            integer,
    dim_date_id       integer not null,
    dim_tags_tag_id   integer not null,
    view_count        integer,
    score             integer
)
logging;

alter table fact_tag_on_post add constraint fact_tag_on_post_pk primary key ( fact_id );

alter table fact_tag_on_post
    add constraint fact_tag_on_post_dim_date_fk foreign key ( dim_date_id )
        references dim_date ( id )
    not deferrable;

alter table fact_tag_on_post
    add constraint fact_tag_on_post_dim_tags_fk foreign key ( dim_tags_tag_id )
        references dim_tags ( tag_id )
    not deferrable;

alter table fact_tag_on_post
drop column tag_id;

create or replace trigger dim_date_id_auto_inc
    before insert
    on dim_date
    for each row

begin
    select dim_date_ids.nextval
    into :new.id
    from dual;
end;

create or replace trigger dim_tags_id_auto_inc
    before insert
    on dim_tags
    for each row

begin
    select dim_tags_ids.nextval
    into :new.tag_id
    from dual;
end;

create or replace trigger fact_tags_on_post_auto_inc
    before insert
    on fact_tag_on_post
    for each row

begin
    select fact_tag_on_post_ids.nextval
    into :new.fact_id
    from dual;
end;

insert into dim_tags(tag_value)
select distinct tagname
from tags;

insert into fact_tag_on_post(dim_date_id,dim_tags_tag_id,view_count,score)
select dd.id, dt.tag_id, p.viewcount, p.score
from posts p join  posttags pt on p.id = pt.postid join tags ts on pt.tagid = ts.id join dim_tags dt on ts.tagname = dt.tag_value join dim_date dd on p.creationdate = dd.date_value
where viewcount is not null;

select *
from fact_tag_on_post join dim_tags dt on fact_tag_on_post.dim_tags_tag_id = dt.tag_id join dim_date dd on fact_tag_on_post.dim_date_id = dd.id;

select *
from dim_date;