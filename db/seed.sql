
drop table if exists users;

create table users(
    id integer primary key,
    name text,
    password_digest text
);


drop table if exists rooms;

create table rooms(
    id integer primary key,
    hash_text text,
    name text,
    number integer,
    show_prev_writer boolean,
    seconds integer
);


drop table if exists room_users;

create table roomusers(
    id integer primary key,
    room_id integer,
    user_id integer,
    index_in_room integer
);


drop table if exists writes;

create table writes(
    id integer primary key,
    room_id integer,
    index_in_room integer,
    content text
);
