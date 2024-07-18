# webtrans24
webtrans for distribution, 2024 snapshot

LDC's transcription tool, normally called webtrans, is derived from software called UA,
and the two names are basically equivalent.  This README
is only concerned with the installation of the software.

# UA

LDC's Universal Annotator is web based, customizable annotation software, that can be
installed locally or in the cloud.  UA is a Ruby on Rails app, although like
most modern web apps it's largely written in Javascript.

## Local Installation

UA is a web app, so using it locally means the server side software is also local.
In other words, to simulate a normal desktop application installed on your local
machine, you actually just use your browser to connect to a local server.
Local installation is made much easier with the Docker ecosystem.  In short, you
install docker first, then docker installs everything else.

### Docker

There's no single way to install docker, even on one platform.  On Mac OS, we
recommend creating a dockerhub account and installing Docker Desktop.  Check out
docker.com, hub.docker.com, and other tutorials on docker to see what's best for
you.  In the end you need the `docker-compose` command available on your command line.
The first time you run docker it may take a while since other software is installed.
On subsequent runs the app should start fairly quickly.  In the terminal where it's
started, Control-C should be good enough to shut everything down.  For more details,
see the documentation for the `docker` and `docker-compose` commands.

### Install

Once you have docker, follow the steps below.  The `docker-compose` command will build
and run four different containers, `web`, `vite`, `database`, and `redis`.  The
web container runs Rails, while the vite container runs Vite.  While the running
containers do different things, you can see from the compose file that the
container image is the same for both, and this fact is relevant below.

1. Clone the repo.
2. `cd webtrans24`
3. `cp envv/development/aws .envv/development/aws`
4. `docker-compose up`

Because the web and vite containers use the same image, they will both attempt to
initialize the database, and it doesn't matter which one succeeeds.  The output
should indicate that one container performs several initialization steps, while
the other exits because it can't duplicate information in the database.  After
a few minutes, the successful container will attempt to start a server.
Whether it succeees or not, since the other container exited, you need to
restart everything.

5. After some time, Control-C to quit all containers
6. `docker-compose up`

Rails and Vite should both sucessfully start.  Rails uses here a server called
Puma, and you should see output from that.

7. Browse to http://localhost:3000
8. Click Create Account
9. Enter the info and Click Sign in

New users don't automatically have any permissions.
If you're the one installing the software, you probably want to log in to the
database and make yourself an admin.   For a local install, run the following
in a separate shell (but also from the `webtrans24` directory).

    docker-compose exec web bin/rails c
    
This puts you into a rails shell, which has access to the database.  In that shell,
run the following.

    User.first.toggle! :admin
    
You can exit the rails shell with Control-D.

10. Set your user to admin and refresh

When you created your account, you were redirected to https://localhost:3000/users/1, which is
your home page.  You would see some tabs and an empty table.  After setting yourself to admin
in the database, you can refresh the page, and you should see many more tabs, since admins
have access to all features.

### Restarting the app

As stated above, `docker-compose up` starts the app by starting several docker containers at once.
If this terminal is still open, Control-C should shut down the app, but you can also
run `docker-compose down` from the same directory to shut down all the containers.  For many people, this is as much
as you need to know, but many more options are available with docker and docker-compose,
and checking out the documentation is recommended.

### New Local Installations

Sometimes it might be desirable to create a new installation of the software.  This
can't be done by simply copying (or cloning) the code to a new directory and running
from there, because the app will end up connecting to the same database if you're on the same machine.  One option
would be to wipe the database, but sometimes that's not desirable either.  You
might like to keep the database you have, but also see what happens when starting
over from scratch; therefore you can make a new database.  The environment file `.envv/development/database`
names a database `myapp_development` which tells the app which database to connect to.
If you want to create a new database, make sure the app is already running,
and run the following command in a separate shell after replacing `NAME` with a new database name.

    docker-compose exec web rails database:change[NAME]
    
This will rewrite the environment file with the specified database name, which is sufficient
to connect to that database but not to actually create it.  The first time the postgres docker image
is used, the named database (`myapp_development` in this case) is created, but that only works the first time.
The above command for rewriting the environment file will also print out a
command which you must use to create the new database.  Run the given command, restart the app, and the app
will now be pointing to the new database.  To switch back to `myapp_development`, you can
simply run

    docker-compose exec web rails database:change[myapp_development]
    
and restart the app.  This is the original database so you don't need to run the printed creation command.

### Production

The included Dockerfile has multiple stages, but the docker-compose.yml file is only targeting the stage
called `dev`.  The later stages illustrate a possible production build, but it's only an illustration,
and may or may not be appropriate for your situation.

