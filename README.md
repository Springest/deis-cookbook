# Deis Cookbook
The [opdemand/deis-cookbook](https://github.com/opdemand/deis-chef) project
contains Chef recipes for provisioning Deis nodes.
To get started with your own private PaaS, check out the
[Deis](https://github.com/opdemand/deis) project.

## Requirements

The Deis cookbook is designed to work with **Ubuntu 12.04 LTS**.  While other Ubuntu or Debian distros may work, they have not been tested.

#### Cookbooks

Deis depends on the following cookbooks:

- `apt` - for managing Ubuntu PPAs
- `sudo` - for managing /etc/sudoers.d
- `rsyslog` - for configuring log routing and aggregation

[Berkshelf](http://berkshelf.com) is used for managing cookbook dependencies.

    bundle install    # to install required gems, including berkshelf
    berks install     # to install cookbooks to the berkshelf directory
    berks upload      # to upload cookbooks to your chef server

# Attributes

```ruby
# base
default.deis.dir = '/opt/deis'
default.deis.username = 'deis'
default.deis.group = 'deis'
default.deis.log_dir = '/var/log/deis'
default.deis.devmode = false # set to true to disable repo syncing

# docker
default.deis.docker.key_url = 'https://get.docker.io/gpg'
default.deis.docker.deb_url = 'https://get.docker.io/ubuntu'
default.deis.docker.version = '0.7.6'

# database
default.deis.database.name = 'deis'
default.deis.database.user = 'deis'

# server/api
default.deis.controller.dir = '/opt/deis/controller'
default.deis.controller.repository = 'https://github.com/opdemand/deis.git'
default.deis.controller.revision = 'master'
default.deis.controller.debug = 'False'
default.deis.controller.workers = 4
default.deis.controller.worker_port = 8000
default.deis.controller.http_port = 80
default.deis.controller.https_port = 443
default.deis.controller.log_dir = '/opt/deis/controller/logs'

# gitosis
default.deis.gitosis.dir = '/opt/deis/gitosis'
default.deis.gitosis.repository = 'git://github.com/opdemand/gitosis.git'
default.deis.gitosis.revision = 'master'

# build
default.deis.build.dir = '/opt/deis/build'
default.deis.build.slug_dir = '/opt/deis/build/slugs'
default.deis.build.pack_dir = '/opt/deis/build/packs'
default.deis.build.builder_dir = '/opt/deis/build/slugbuilder'
default.deis.build.repository = 'https://github.com/flynn/slugbuilder'
default.deis.build.revision = 'master'

# runtime
default.deis.runtime.dir = '/opt/deis/runtime'
default.deis.runtime.runner_dir = '/opt/deis/runtime/slugrunner'
default.deis.runtime.slug_dir = '/opt/deis/runtime/slugs'
default.deis.runtime.repository = 'https://github.com/flynn/slugrunner'
default.deis.runtime.revision = 'master'

# rsyslog
default['rsyslog']['log_dir'] = '/var/log/rsyslog'
default['rsyslog']['protocol'] = 'tcp'
default['rsyslog']['port'] = 514
default['rsyslog']['server_search'] = 'run_list:recipe\[deis\:\:controller\]'
default['rsyslog']['per_host_dir'] = '%HOSTNAME%'

# build
default.deis.buildpacks = {
 'heroku-buildpack-java' => ['https://github.com/heroku/heroku-buildpack-java.git', 'master'],
 'heroku-buildpack-ruby' => ['https://github.com/heroku/heroku-buildpack-ruby.git', 'master'],
 'heroku-buildpack-python' => ['https://github.com/heroku/heroku-buildpack-python.git', 'master'],
 'heroku-buildpack-nodejs' => ['https://github.com/gabrtv/heroku-buildpack-nodejs', 'master'],
 'heroku-buildpack-play' => ['https://github.com/heroku/heroku-buildpack-play.git', 'master'],
 'heroku-buildpack-php' => ['https://github.com/CHH/heroku-buildpack-php.git', 'master'],
 'heroku-buildpack-clojure' => ['https://github.com/heroku/heroku-buildpack-clojure.git', 'master'],
 'heroku-buildpack-go' => ['https://github.com/kr/heroku-buildpack-go.git', 'master'],
 'heroku-buildpack-scala' => ['https://github.com/heroku/heroku-buildpack-scala', 'master'],
 'heroku-buildpack-dart' => ['https://github.com/igrigorik/heroku-buildpack-dart.git', 'master'],
 'heroku-buildpack-perl' => ['https://github.com/miyagawa/heroku-buildpack-perl.git', 'carton'],
}
```

# Usage

#### deis::controller
The controller recipe will create a complete Deis controller on a single node including:

 * PostgreSQL database
 * Django API Server 
 * RabbitMQ installation
 * Celery worker service
 * Nginx site for API 
 * Gitosis server
 * Docker daemon
 * Docker-based build system
 * Nginx site for hosting build "slugs"
 * Rsyslog server

The controller will iterate over the `deis-build` databag and configure gitosis access controls in order to restrict `git push` access to repositories.

#### deis::runtime
The runtime recipe will prepare a node for hosting Docker containers as part of a Deis runtime layer.  This recipe will configure:

 * Docker daemon
 * Buildstep Docker image
 * Rsyslog client

The runtime recipe will iterate over the `deis-formations` databag and configure and start upstart daemons for any Docker containers assigned to this node.

#### deis::proxy
The proxy recipe will prepare a node for routing traffic to containers in a Deis runtime layer.  This recipe will configure:

 * Nginx site
 * Rsyslog client

The proxy recipe will iterate over the `deis-formations` databag and configure Nginx backends for any Docker containers assigned to a given formation.

### Notes

The destination for rsyslog clients is determined by a Chef search for recipe[deis::controller], and using the `ipaddress` attribute.

# License

Copyright:: 2013, OpDemand LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
