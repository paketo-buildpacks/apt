# Paketo Buildpack for Apt

## Buildpack ID: `paketo-buildpacks/apt`
## Registry URLs: `docker.io/paketobuildpacks/apt`

The Paketo Buildpack for Apt is a Cloud Native Buildpack that that allows you to install additional dependencies for both build and runtime using Apt. This *only* works on containers that include a shell and Apt itself.

## Behavior

This buildpack will participate if all the following conditions are met:

* `<APPLICATION_ROOT>/Aptfile` exists

The buildpack will do the following:

* Read the `<APPLICATION_ROOT>/Aptfile`.
* For each package from the `Aptfile`, it will download and install the package into a layer.

## Configuration

| Environment Variable | Description |
| -------------------- | ----------- |
| `BP_APT_RUN_PACKAGES` | Comma-separated list of packages pre-installed in the run image (optional). Use when the run image differs from the build image. |

By default, the buildpack automatically detects the run image's base packages for standard Paketo stacks (jammy, noble). If you use a custom run image with additional packages, set `BP_APT_RUN_PACKAGES` to a comma-separated list of packages already present. You can generate this list from your run image:

```
docker run --rm <your-run-image> dpkg-query -W -f='${Package}\n' | sort | tr '\n' ','
```

### Aptfile

Configuration is applied through the `Aptfile`. Each line contains one entry and the file uses `LF` as for a line ending.

The simplest configuration is to just add a package name. This will be looked up in the repos known to apt.

```
libexample-dev
```

You may also point to a `.deb` file.

```
http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.1/wkhtmltox-0.12.1_linux-precise-amd64.deb
```

You can add custom apt repos as well. This is only required if you are using packages outside of the standard repositories available to the container. For Paketo projects, that would be the standard Ubuntu repositories.

```
:repo:deb http://cz.archive.ubuntu.com/ubuntu artful main universe
```

The buildpack also supports adding additional GPG keys, for use with custom repos. This first example uses the `.gpg` format.

```
:repo:key https://example.com/repo-signing-key.gpg
```

You may also use the `.asc` format.

```
:repo:key https://example.com/repo-signing-key.asc
```

You can even import from `keyserver.ubuntu.com`.

```
:repo:key CADA0F77901522B3
```

or from a file URL. This must be a relative link to a key that's bundled with the application. You cannot reference arbitrary full paths, i.e. `file:///etc/keys/foo.asc` will not work.

```
:repo:key file://key.asc
```

## Bindings

The buildpack optionally accepts the following bindings: None

## License

MIT

Please note that this is not the typical license for Paketo projects, but because this project was contributed to us under the MIT license, we need to continue using that license.
