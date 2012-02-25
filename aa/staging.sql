

drop table seattleaadirectoryorig;
create table seattleaadirectoryorig (
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

drop table meetingsource;
create table meetingsource (
meetingserialid SERIAL,
importrunuuid uuid,
importtime timestamp with time zone default (now()),
importhost text,
sourceurl text,
updateddate timestamp,
dayofweek text,
lastupdated date,
rownum int,
divisions text,
time text,
openclosed text,
name text,
address text,
notedisp text);

create table 