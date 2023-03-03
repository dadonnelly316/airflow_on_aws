# database is not sent by default when creating a postgres database in docker-compose. 
# it will take the POSTGRES_USER enviormental variable (database user) and use that as the db name


# generic database url : dialect+driver://username:password@host:port/database


# - ./build/postgres_build:/docker-entrypoint-initdb.d
# from https://hub.docker.com/_/postgres?tab=description 
if you would like to do additional initialization in an image derived from this one, add one or more *.sql, *.sql.gz, or *.sh scripts under /docker-entrypoint-initdb.d (creating the directory if necessary). After the entrypoint calls initdb to create the default postgres user and database, it will run any *.sql files, run any executable *.sh scripts, and source any non-executable *.sh scripts found in that directory to do further initialization before starting the service.

Warning: scripts in /docker-entrypoint-initdb.d are only run if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup. One common problem is that if one of your /docker-entrypoint-initdb.d scripts fails (which will cause the entrypoint script to exit) and your orchestrator restarts the container with the already initialized data directory, it will not continue on with your scripts.



# to start db service, you want to wait until it's healthy:
# https://docs.docker.com/compose/startup-order/



# postgres will automatically create a datase with the same name as the user. a lot of the postgres commands 
# will also automatically look for a database with the same name unless you expilicity pass in a different db name. 
# so, it's best to just keep the schema the same name as the user because you cannot control all the dependancies

# postgres will also create a user called 'postgres' automatically on the source OS system. this has all the needed privlilages.
# so, it might be best not to mess with this and just use the default