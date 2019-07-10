CREATE TABLE directors (did integer primary key, name varchar(32));
CREATE TABLE movies (mid integer primary key, name varchar(64), year integer);
CREATE TABLE director_movie (
    did integer, mid integer,
    FOREIGN KEY(did) REFERENCES directors(did),
    FOREIGN KEY(mid) REFERENCES movies(mid)
);

CREATE UNIQUE INDEX movie_dirx on director_movie(did,mid);

INSERT INTO directors (name) VALUES ("Jim Jarmusch"), ( "Tim Burton");
INSERT INTO directors VALUES(3,'Lana Wachowski');
INSERT INTO directors VALUES(4,'Lilly Wachowski');
INSERT INTO directors VALUES(5,'Alejandro González Iñárritu');

INSERT INTO movies (name, year) VALUES
    ("The Dead Dont Die", 2019),
    ("Night on Earth", 1991),
    ("Only Lovers Left Alive", 2013);
INSERT INTO movies (name, year) VALUES
    ("Ed Wood", 1994),
    ("Sleepy Hollow", 1999),
    ("Edward Scissorhands", 1990);
INSERT INTO movies (name, year)
    VALUES('The Matrix', 1999),
    ('Amores Perros', 2000);

INSERT INTO director_movie (did, mid) VALUES (1,1), (1,2), (1,3), (2,4), (2,5), (2,6);

INSERT INTO director_movie VALUES(3,7), (4,7), (5,8);


