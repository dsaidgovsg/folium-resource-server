# Folium Resource Server

Simple server to host folium Javascript and CSS resources for custom-hosted
Folium maps.

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

2. `leaflet` Javascript and CSS files. These are currently not officially
   supported for overriding, which is the main issue of not being able to custom
   host the entire `folium` rendered HTML maps.

   This repository provides the extracted JS and CSS files and is able to custom
   host these static files for access.

   To overcome the issue of overriding the URLs to these resources, this
   repository works in tandem with <https://github.com/guangie88/folium>. You
   will need to perform installation of the `folium` library from this source
   instead of the official source. Be rest assured that the only file changes
   in this custom `folium` always starts from a release tag from the official
   source, and only opens up the possibility of changing the JS and CSS URLs.

   Note that the tag values found in the branch names should correspond to the
   branch to use in the above repository.

   For e.g. `v0.10.1-release` in this repository will correspond to custom branch
   `v0.10.1+urloverride` in <https://github.com/guangie88/folium>.

## How to set-up

### Folium JS and CSS resources

The set-up is Docker centric (which is good right?) and currently uses Caddy 2
to host the static files.

You will need both `docker` and `docker-compose`. Simply run the following:

```bash
docker-compose up --build
```

to get a running static HTTP file server. To test that this is working, enter
the following link into your web browser:

```txt
http://localhost:8080/leaflet.awesome.rotate.css
```

You should see the contents of the CSS being displayed.

### Custom Folium library

Assuming you are using `pip` with `requirements.txt` file, you can install
`folium` from the above custom repository with the following requirement link
in `requirements.txt`

```txt
git+git://github.com/guangie88/folium.git@v0.10.1+urloverride#egg=folium
```

and then run

```bash
pip install -r requirements.txt
```

to install the custom `folium` package.

When using this custom `folium` library, the code should exactly be the same as
before, but if you wish to use the static JS and CSS resources here, you need to
make construct your `folium` `Map` object like this:

```python
import os
# ...

FOLIUM_SERVER_URL = "http://localhost:8080"  # Assuming this repo server is running on localhost:8080

folium.Map(
    # ...
    override_js={
        "leaflet": os.path.join(FOLIUM_SERVER_URL, "leaflet@1.5.1/leaflet.js"),
        "jquery": os.path.join(FOLIUM_SERVER_URL, "jquery-1.12.4.min.js"),
        "bootstrap": os.path.join(FOLIUM_SERVER_URL, "bootstrap@3.2.0/bootstrap.min.js"),
        "awesome_markers": os.path.join(FOLIUM_SERVER_URL, "leaflet.awesome-markers@2.0.2/leaflet.awesome-markers.js"),
    },
    override_css={
        "leaflet_css": os.path.join(FOLIUM_SERVER_URL, "leaflet@1.5.1/leaflet.css"),
        "bootstrap_css": os.path.join(FOLIUM_SERVER_URL, "bootstrap@3.2.0/bootstrap.min.css"),
        "bootstrap_theme_css": os.path.join(FOLIUM_SERVER_URL, "bootstrap@3.2.0/bootstrap-theme.min.css"),
        "awesome_markers_font_css": os.path.join(FOLIUM_SERVER_URL, "font-awesome@4.6.3/font-awesome.min.css"),
        "awesome_markers_css": os.path.join(FOLIUM_SERVER_URL, "leaflet.awesome-markers@2.0.2/leaflet.awesome-markers.css"),
        "awesome_rotate_css": os.path.join(FOLIUM_SERVER_URL, "leaflet.awesome.rotate.css"),
    },
)
```

## Alternative set-up

For the Folium resource static file server, you could also just take all the
files in [`static`](static/) and host them in any static file webserver that you
prefer.
