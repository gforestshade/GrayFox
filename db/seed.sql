
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
    last_update_time integer,
    show_writer boolean,
    seconds integer,
    orders text,
    phase integer,
    count integer
);


drop table if exists room_users;

create table room_users(
    id integer primary key,
    room_id integer,
    user_id integer,
    index_room integer,
    is_host boolean
);


drop table if exists writes;

create table writes(
    id integer primary key,
    hash_text text,
    room_id integer,
    index_room integer,
    title text,
    content text
);
