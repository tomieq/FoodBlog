## Quickstart

```bash
# build image
docker build -t tomieq/awstats:1.0 .
```

```bash
# start the container
docker run -d --restart always -p 8085:80 \
    --name awstats \
    --volume food_volume:/food_volume:ro \
    --volume awstats_storage:/awstats_storage \
    --env TZ="Europe/Warsaw" \
    tomieq/awstats:1.0

# ensure awstats can read your logs
docker exec awstats awstats_updateall.pl now
```


Add this line to your `/etc/crontab` to let Awstats analyze your logs every 10 minutes:


Run `crontab -e` adding entry:
```
*/10 * * * * root docker exec awstats awstats_updateall.pl now > /dev/null
```

By default, the timezone in the container will be UTC. To configure a different
timezone in your container, set the environment variable `TZ` to your timezone,
adding the following to your command line at the container start:

```
    --env TZ="Antarctica/South_Pole"
```

# Advanced

## Run extra commands on the entrypoint

If you need to execute some command before httpd starts (i.e. a cron daemon inside
the container), you can bind-mount a file `/usr/local/bin/autorun.sh` that will
be executed during the entrypoint. Add the following volume

```
...
    --volume /path/to/my/autorun.sh:/usr/local/bin/autorun.sh:ro
...
```
