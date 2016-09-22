# Using Docker to run Canvas
## Prerequisites

You need Docker. Don't have Docker yet? Go [here](getting_docker.md) for details on getting it setup.

## Development

These commands should get you going

```bash
cp docker-compose/config/* config/
docker-compose run --rm web bash -c "bundle exec rake db:create db:initial_setup"
```

Now you can do `docker-compose up` and you should be good to go. If you're
using Dingy or Dory. You should be able to access Canvas by going to: [http://web.canvaslms.docker/](http://web.canvaslms.docker/)

On Linux you should probably run this
```bash
touch mkmf.log .listen_test
chmod 777 !:2 !:3
sudo chown -R `whoami`:9999 .
chmod 775 gems/canvas_i18nliner
chmod 775 . log tmp gems/selinimum gems/canvas_i18nliner
chmod 664 ./app/stylesheets/_brand_variables.scss
```

For more information checkout [Developing with Docker](developing_with_docker.md)
