# Paketo Buildpack for Apt

## Buildpack ID: `paketo-buildpacks/apt`
## Registry URLs: `docker.io/paketobuildpacks/apt`

The Paketo Buildpack for Apt is a Cloud Native Buildpack that allows you to install additional dependencies for both build and runtime using Apt. This *only* works on containers that include a shell and Apt itself.

## Behavior

This buildpack will participate if any of the following conditions are met:

* `<APPLICATION_ROOT>/Aptfile` exists
* `$BP_APT_PACKAGES` is set to a non-empty value
* `$BP_APT_REPOS` is set to a non-empty value

The buildpack will do the following:

* Read the `<APPLICATION_ROOT>/Aptfile` together with the packages and repositories specified via `$BP_APT_PACKAGES` and `$BP_APT_REPOS`.
* For each package, it will download and install the package into a layer.

The `Aptfile` and the `$BP_APT_PACKAGES` / `$BP_APT_REPOS` environment variables can be used together. When both are provided, their entries are merged, sorted, and de-duplicated so there is no ambiguity.

## Configuration

| Environment Variable | Description |
| -------------------- | ----------- |
| `BP_APT_PACKAGES`    | Space-separated list of apt packages to install. Can be used instead of, or in addition to, `Aptfile` when that file cannot be included in the build container (e.g., Spring Boot Gradle plugin's `bootBuildImage`). |
| `BP_APT_REPOS`      | Pipe-separated list of custom apt repository entries. Supports `:repo:deb` and `:repo:key` formats. Can be used instead of, or in addition to, `Aptfile` for corporate/internal repositories. |

### BP_APT_PACKAGES

The `BP_APT_PACKAGES` environment variable provides a way to specify apt packages when `Aptfile` is not available in the build container. This is especially useful with build tools that do not copy project files into the build container, such as the Spring Boot Gradle plugin's `bootBuildImage`. It can also be combined with a physical `Aptfile`; in that case the entries from both sources are merged.

```
BP_APT_PACKAGES="curl wget"
```

This will install the `curl` and `wget` packages. Each package is installed via `apt-get install`.

Note: `.deb` URLs are supported. For custom repositories (`:repo:deb`) and GPG keys (`:repo:key`), see `BP_APT_REPOS` below.

### BP_APT_REPOS

The `BP_APT_REPOS` environment variable provides a way to specify custom apt repositories and GPG keys. Use it alongside `$BP_APT_PACKAGES`, or alongside a physical `Aptfile`, to install packages from corporate or internal repositories. This is useful when you want to bake packages into an image via `Aptfile` but direct where they are fetched from at runtime (for example, different internal repos for dev/staging/prod).

Multiple entries are separated by the pipe character (`|`):

```
BP_APT_REPOS=":repo:deb https://binary.example.com/ubuntu noble main universe|:repo:key https://keyserver.example.com/repo-key.gpg"
```

This adds the repository and GPG key, which are then available to any packages from `BP_APT_PACKAGES` or from an `Aptfile`.

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
