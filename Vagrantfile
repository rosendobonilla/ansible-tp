# vim: ft=ruby syn=ruby fileencoding=utf-8 sw=2 ts=2 ai eol et si
#
# Vagrantfile: ASRALL 2018 Ansible Practice Boilerplate
#
# (c) 2018 Laurent Vallar <val@zbla.net>

ENV['LC_ALL'] = ENV['LANG'] = 'C.UTF-8'

VAGRANT_CPU = ENV['VAGRANT_CPU'] || '2'
VAGRANT_RAM = ENV['VAGRANT_RAM'] || '2048'

VAGRANT_BOX_URL = ENV['VAGRANT_BOX_URL']

fail '$VAGRANT_BOX_URL is not set, abording.' unless VAGRANT_BOX_URL

Vagrant.configure('2') do |config|
  config.ssh.forward_x11 = false
  config.ssh.forward_agent = true

  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.define('sandbox.local') do |vagrant|
    vagrant.vm.hostname = 'sandbox.local'

    vagrant.vm.box = 'ASRALL-2018_TP_ansible'
    vagrant.vm.box_url = VAGRANT_BOX_URL

    vagrant.vm.provider :virtualbox do |virtualbox|
      virtualbox.customize ['modifyvm', :id, '--cpus', VAGRANT_CPU]
      virtualbox.customize ['modifyvm', :id, '--memory', VAGRANT_RAM]

      # Disable audio
      virtualbox.customize ['modifyvm', :id, '--audio', 'none']

      # Enabling the I/O APIC is required for 64-bit guest operating systems.
      # it is also required if you want to use more than one virtual CPU in a VM.
      virtualbox.customize ['modifyvm', :id, '--ioapic', 'on']
      # Enable the use of hardware virtualization extensions (Intel VT-x or AMD-V)
      # in the processor of your host system
      virtualbox.customize ['modifyvm', :id, '--hwvirtex', 'on']
    end

    config.vm.post_up_message = <<~EOF
      ASRALL-#{Time.now.year} TP Ansible

               ___|                  | |
             \\___ \\   _` | __ \\   _` | __ \\   _ \\\\ \\  /
                   | (   | |   | (   | |   | (   |`  <
             _____/ \\__,_|_|  _|\\__,_|_.__/ \\___/ _/\\_\\


      /!\\ Don't forget to use 'ops' account after 'vagrant ssh'
           * become 'ops': 'sudo su - ops'
           * 'ops' account has sudo access
           * 'ops' password is… 'ops'
           * 'ops' ssh client config is set for LXC hosts
      \n
    EOF
  end
end
