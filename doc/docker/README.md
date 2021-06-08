# Using Docker to run Canvas
## Prerequisites

You need Docker. Don't have Docker yet? Go [here](getting_docker.md) for details on getting it setup.

## Development

Just on Linux (skip this on OSX), you may want to run this to avoid a few
permissions issues first by granting Canvas docker containers write access to
your Canvas folder:

```bash
setfacl -Rm u:9999:rwX,g:9999:rwX .
setfacl -dRm u:9999:rwX,g:9999:rwX .
sudo addgroup --gid 9999 docker-instructure
sudo usermod -a -G docker-instructure $USER
```

After logging back into your system (to recognize your new group), you should be
able to edit or delete any files created by Canvas docker containers. If you're
using this approach to grant Canvas write access, you can also disable the
default built-in usermod hack that runs Canvas containers as your host UID
instead (since this has been known to cause problems). This can be done by
adding this to your `~/.bash_profile`:

```bash
export CANVAS_SKIP_DOCKER_USERMOD=1
```

For everyone now, this command should get you going:

```bash
./script/docker_dev_setup.sh
```

Be sure to pay attention to any `Next Steps` output from the script that you may need to run.

Now you can do `docker-compose up` and you should be good to go. If you're
using Dinghy or Dory. You should be able to access Canvas by going to: [http://canvas.docker/](http://canvas.docker/)

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
