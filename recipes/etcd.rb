
# start the container and create an upstart service

docker_container node.deis.etcd.container do
  container_name node.deis.etcd.container
  detach true
  env ["PUBLIC_IP=#{node.deis.public_ip}",
       "ETCD_PORT=#{node.deis.etcd.port}",
       "ETCD_PEER_PORT=#{node.deis.etcd.peer_port}",
       "ETCD_NODE_NAME=#{node.hostname}"]
  image node.deis.etcd.image
  port ["#{node.deis.etcd.port}:#{node.deis.etcd.port}", 
        "#{node.deis.etcd.peer_port}:#{node.deis.etcd.peer_port}"]
end
 
# install etcdctl on the host

bash 'install-etcdctl' do
  cwd '/tmp'
  code <<-EOH
    wget -O etcd.tar.gz #{node.deis.etcd.url}
    tar xfz etcd.tar.gz
    mv etcd-v0.2.0-Linux-x86_64/etcdctl /usr/local/bin
    chown -R root:root /usr/local/bin/etcdctl
    rm -rf etcd.tar.gz etcd-v0.2.0-Linux-x86_64
    EOH
  creates '/usr/local/bin/etcdctl'
end

# wait for etcd to be listening

ruby_block 'wait-for-etcd' do
  block do
    Connect.wait_tcp(node.deis.public_ip, node.deis.etcd.port, seconds=5)
  end
end

# publish chef configuration to etcd

# TODO: refactor into library
require 'etcd'
ruby_block 'publish-chef-config' do
  block do
    client = Etcd.client(host: node.deis.public_ip, port: node.deis.etcd.port)
    client.set('/deis/chef/url', "#{Chef::Config[:chef_server_url]}")
    client.set('/deis/chef/clientName', "#{Chef::Config[:node_name]}")
    client.set('/deis/chef/clientKey', "#{Base64.strict_encode64(File.read(Chef::Config[:client_key]))}")
    client.set('/deis/chef/validationName', "#{Chef::Config[:validation_client_name]}")
    client.set('/deis/chef/validationKey', "#{Base64.strict_encode64(File.read(Chef::Config[:validation_key]))}")
  end
  not_if {
    begin
      client = Etcd.client(host: node.deis.public_ip, port: node.deis.etcd.port)
      client.get('/deis/chef')
      true
    rescue Net::HTTPServerException
      false
    end
  }
end