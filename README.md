# Folium Resource Server

![CI Status](https://img.shields.io/github/workflow/status/dsaidgovsg/folium-resource-server/CI/v0.10.1-release?label=CI&logo=github&style=for-the-badge)

Simple server to host folium Javascript and CSS resources for custom-hosted
Folium maps.

Also contains a bash script to scrape the `folium` repository and download all
the external resources required for hosting.

## Motivation

Ever wished that you were able to server Folium maps within self-hosted /
non-Internet environment? This repository fulfils the other half of the
resources that is required for Folium rendered HTML to run.

Folium requires two sets of external resources:

1. Tileserver resources. This is official supported by the latest official
   `folium` library.

   Check these resources:
   - <https://github.com/maptiler/tileserver-gl> for the custom hosting of map
     tiles.
   - <https://python-visualization.github.io/folium/modules.html> for how to
     specify the custom tileserver URL.

2. Javascript and CSS files required by many third-party libraries of `folium`,
   such as `leaflet`. These are currently not officially supported for
   overriding, which is understandable because of the sheer amount of external
   JS and CSS resources.

   This repository provides the extracted JS and CSS files (and the
   corresponding extra resources for the CSS files), and is able to custom
   host these static files for access.

   To overcome the issue of overriding the URLs to these resources, this
   repository works in tandem with
   <https://github.com/dsaidgovsg/folium-override-server>. The generated
   [external/folium-css.json](external/folium-css.json) and
   [external/folium-js.json](external/folium-js.json) files are meant for the
   above repository to use, to know how to string replace all found external
   URLs to point to this repository hosted resources in `static` directory.

   The tag release system here follows this format `vX.Y.Z_folium-v0.10.1`. The
   `vX.Y.Z` part is the semver for this repository, while the `folium-v0.10.1`
   part is to match the resources that was extracted from `folium` `v0.10.1`.

   In general, the users should be more mindful of the `folium` version since
   it needs to match with the `folium` version that was used to generate the
   `folium` map. There is probably a high chance that a slight mismatch version
   of `folium` and this repository would work, but it is not a 100% guarantee.

## Set-Up

The set-up is Docker centric and uses NGINX to host the static files.

### Pull and run

The built image is already available. This pulls and just runs the webserver.

```bash
docker pull dsaidgovsg/folium-resource-server:v0.1.3_folium-v0.10.1
docker run --rm -it -p 8080:8080 dsaidgovsg/folium-resource-server:v0.1.3_folium-v0.10.1
```

To test that this is working, enter the following link into your web browser:

```txt
http://localhost:8080/code.jquery.com/jquery-1.12.4.min.js
```

You should see the contents of the JS being displayed.

### Manual build

You will need both `docker` and `docker-compose`. Simply run the following:

```bash
docker-compose up --build
```

to get a running static HTTP file server.

To test that this is working, enter the following link into your web browser:

```txt
http://localhost:8080/code.jquery.com/jquery-1.12.4.min.js
```

You should see the contents of the JS being displayed.

## Alternative set-up

For the Folium resource static file server, you could also just take all the
files in [`static`](static/) and host them in any static file webserver that you
prefer.

## How to refresh the resources and external configuration

Simply run `static-fetch.sh`. Note that this requires a higher version of
`bash`, and has been tested to work on Ubuntu 18.04 LTS's default `bash`.

Both the `static` directory which contains the downloaded JS and CSS resources to host, as well as
the `external` directory which contains the configuration for
<https://github.com/dsaidgovsg/folium-override-server> to use will be updated.

There are flags that can be added to tweak the behaviour of the script, run

```bash
./static-fetch.sh -h
```

to find out more.
