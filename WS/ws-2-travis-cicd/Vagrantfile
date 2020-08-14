# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Set VM box
  config.vm.box = "ubuntu/xenial64"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Mount current directory
  config.vm.synced_folder ".", "/vagrant_data"

  # Setup hardware
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false

    # CPUs
    vb.cpus = 2

    # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end
  #

  # Install Docker
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common socat
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
  SHELL
end
