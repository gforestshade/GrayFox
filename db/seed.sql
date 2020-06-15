
drop table if exists users;

create table users(
    name text,
    password_digest text
);


drop table if exists rooms;

create table rooms(
    hash_text text,
    show_prev_writer boolean,
    seconds integer
);


drop table if exists room_users;

create table room_users(
    room_id integer,
    user_id integer,
    index_in_room integerx
);


drop table if exists writes;

create table writes(
    room_id integer,
    index_in_room integer,
    content text
);
