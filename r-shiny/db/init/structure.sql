create table summary (
    state varchar,
    trump16 int,
    clinton16 int,
    otherpres16 int,
    insert_date varchar
);

copy summary (
    state,
    trump16,
    clinton16,
    otherpres16,
    insert_date
) from '/var/lib/postgresql/csvs/summary-data.csv' 
    delimiter ',' 
    null 'NA'
    csv
    header;
