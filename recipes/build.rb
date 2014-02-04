include_recipe 'deis::docker'

# create build root directory
directory node.deis.build.dir do
  user node.deis.username
  group node.deis.group
end

# checkout the slugbuilder project
git node.deis.build.builder_dir do
  user node.deis.username
  group node.deis.group
  repository node.deis.build.repository
  revision node.deis.build.revision
  action :sync
end

# create a directory to host slugs
directory node.deis.build.slug_dir do
  user node.deis.username
  group node.deis.group
  mode 0777 # nginx needs write access
end

# create docker image used to run heroku buildpacks
bash 'create-slugbuilder-image' do
  cwd node.deis.build.builder_dir
  code 'docker build -t deis/slugbuilder .'
  not_if 'docker images | grep deis/slugbuilder'
end

directory node.deis.build.pack_dir do
  user node.deis.username
  group node.deis.group
  mode 0755
end

# synchronize buildpacks to use during slugbuilder execution
node.deis.buildpacks.each_pair { |path, repo|
  url, rev = repo
  git "#{node.deis.build.pack_dir}/#{path}" do
    user node.deis.username
    group node.deis.group
    repository url
    revision rev
    action :sync
  end
}
