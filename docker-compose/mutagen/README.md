# EXPERIMENTAL - Using Mutagen with Docker for Canvas Development

Using [Mutagen](https://mutagen.io) in your local docker development with canvas you can avoid bind and/or nfs mounts
which can be slow or complicated to set up. While not up to the millisecond like the bind or nfs mounts, mutagen
synchronizes fairly quickly and should be fine in almost all cases. The big win is the performance, especially on macOS,
will be much better when executing code within the container.

Mutagen can [work with docker-compose](https://mutagen.io/documentation/orchestration/compose) to have the ease of
docker-compose along with the syncing of Mutagen. This support from mutagen is in beta and is in flux. This document
will be updated as mutagen continues its development.

In this directory you'll find docker-compose override files set up to run with mutagen. The two biggest changes from
what we've traditionally done are we now have a docker volume for code and an x-mutagen stanza in the docker-compose
override that sets up the mutagen sync session.

The x-mutagen configuration in this sample file makes an assumption that the syncing strategy we want is
`two-way-resolved`. This is a bidirectional synchronization mode, except that the local environment automatically wins
all conflicts, including cases where local deletions would overwrite the docker volumes modifications or creations.

# Installing mutagen

Follow the instructions at https://mutagen.io/documentation/introduction/installation to install the beta channel.
Mutagen 0.12 beta has is the version we need to support mutagen compose.

# Setting up and running canvas

You'll want to do your initial setup using manual steps documented in
[develping_with_docker.md](../../doc/docker/developing_with_docker.md) but using the `docker-compose.override.yml` file
in this directory as your base. (We cannot use the `docker_dev_script.sh` yet because it is not yet aware that you may
want the mutagen environment running.)

The one difference from normal docker development is in many cases you'll use `mutagen compose` instead of
`docker-compose`. This ensures that the mutagen daemon is running as well as the needed mutagen container.

One trick is to do a `mutagen compose up --no-start`. This will ensure the mutagan environment is set up and running,
but won't start any of your containers.

## Suggested series of steps for setting up canvas
1. setup dinghy-http-proxy per the instructions at https://github.com/codekitchen/dinghy-http-proxy
2. `mutagen compose build --pull`
3. This step will have mutagen start so it can sync canvas code into the docker volume: `mutagen compose up --no-start
   web`
4. This step fixes a permission issue in /usr/src/app, so your docker environment can create new files that can be
   synced back to your local environment in the root directory: `mutagen compose run -u root --rm web chown
   docker:docker /usr/src/app` You will see mutagen complain about not supporting run fully and also docker messages
   about an orphan container (which is mutagan's agent.) That is normal.
5. `mutagen compose run --rm web ./script/install_assets.sh`
6. `mutagen compose run --rm web bundle exec rake db:create`
7. `mutagen compose run --rm web bundle exec rake db:initial_setup`
8. Enjoy your canvas

Really, for any of the `mutagen compose run` steps you could just use `docker-compose run` since mutagen doesn't do much
there, but its worth getting into the `mutagen compose` habit. (Although, be aware based on recent chatter in the
mutagen forums, this will go away.)

# FAQ

**Q: Help! My file changes aren't reflecting in the docker container if I use `mutagen compose run ...`**

**A:** Be sure to run `mutagen compose up --no-start web` first or files won't sync. (Run doesn't activate the

**Q: Something seems to be wrong with the sync process, how do I get more information?**

**A:** Run `mutagen sync list`

**Q: I'm moving over to using mutagen and switching my docker environment and stuff isn't working. Can you help me?**

**A:** If you've previously have worked on canvas and moved your docker environment as well as switching to mutagen you
can do a few things: 1) confirm your DNS is setup up correctly, 2) make sure your docker environmental variables are
pointing at the right docker environment.
