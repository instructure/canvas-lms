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


### NFS Not Starting

During dinghy boot (normally if you've killed and restarted dinghy since your
last system reboot), you get a message that indicate NFS could not start
and it gives you a path to an error file where you see something like:

```
=== Starting NFS at 2019-09-05T17:31:22-05:00 ===

UNFS3 unfsd 0.9.23 (C) 2009, Pascal Schmidt <unfs3-server@ewetel.net>
bind: Address already in use
Couldn't bind to udp port 19091
```

See this issue on dinghy: https://github.com/codekitchen/dinghy/issues/272

You can reboot your system to clear the zombie process,
or you can use xhyve as your VM backend.