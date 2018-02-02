# How it works

The gist of it is the content of `examples/listen_multiple.rb`, to run it simply do
```
ruby -I . examples/listen_multiple.rb
```
from the project root directory.

# Running the database

Create a new database container from postgres image

```
docker run -d --name cryptodb -v /path/to/csv:/mnt/data -e POSTGRES_PASSWORD=<you_password> -p 5432:5432 postgres:9.6-alpine
```
(optional) you can add a local data directory if you want the database to be directly accessible from the host
```
-v /your/data/dir:/var/lib/postgresql/data
```

Run psql from it

```
docker exec -it cryptodb psql -U postgres
```

or from your application

```
docker run --name some-app --link cryptodb:postgres -d application-that-uses-postgres
```

or directly from the host

```
psql -h <docker-container-ip> -U postgres
```
