# Using Docker to run Canvas
## Prerequisites

You need Docker. Don't have Docker yet? Go [here](getting_docker.md) for details on getting it setup.

## Development

This command should get you going:

```bash
./script/docker_dev_setup.sh
```

Now you can do `docker-compose up` and you should be good to go. If you're
using Dinghy or Dory. You should be able to access Canvas by going to: [http://canvas.docker/](http://canvas.docker/)

On Linux you may want to run this to avoid a few permissions issues:

```bash
touch mkmf.log .listen_test
chmod 777 !:2 !:3
sudo chown -R `whoami`:9999 .
chmod 775 gems/canvas_i18nliner
chmod 775 . log tmp gems/selinimum gems/canvas_i18nliner
chmod 664 ./app/stylesheets/_brand_variables.scss
```

For more information checkout [Developing with Docker](developing_with_docker.md)

## Known Issues

### Long URL Gateway 502

If a URL is long enough, you may see a Gateway 502 error. This problem
has been patched in [dinghy-http-proxy#36](https://github.com/codekitchen/dinghy-http-proxy/pull/36)
however until a new release is cut the follow can be done as a work
around:

In `~/.dinghy/proxy.conf` add the following:

    proxy_buffers 8 1024k;
    proxy_buffer_size 1024k;

Restart dinghy afterwards.
