CREATE TABLE contacts (
 id serial PRIMARY KEY,
 first text NOT NULL,
 last text NOT NULL,
 email text NOT NULL,
 phone varchar(12) NOT NULL,
 username_id integer REFERENCES users (id) NOT NULL
);

CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(10) NOT NULL,
  pass text NOT NULL
);