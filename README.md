# Reproduction of Keycloak race condition when assigning role concurrently 

## Running
1. `docker compose up kc`
1. `docker compose up reproduction`

You should see that some requests do not return `204` status code but instead a `400`.

In Keycloak logs you should see
```
Caused by: java.sql.BatchUpdateException: Batch entry 0 insert into USER_ROLE_MAPPING (ROLE_ID,USER_ID) values (('....'),('...')) was aborted: ERROR: duplicate key value violates unique constraint "constraint_c"
  Detail: Key (role_id, user_id)=(..., ...) already exists.  Call getNextException to see other errors in the batch.
```
