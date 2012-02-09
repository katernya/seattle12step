

drop table seattleaadirectory;
create table seattleaadirectory (
saadid SERIAL,
importrunuuid uuid,
importtime timestamp with time zone default (now()),
importhost text,
sourceurl text,
lastupdated date,
rownum int,
divisions text,
time text,
openclosed text,
name text,
address text,
notedisp text);
