#################################################
#  Licensed Materials -- Property of IBM
#
#  (c) Copyright IBM Corporation, 2014
#      ALL RIGHTS RESERVED.
#
#  US Government Users Restricted Rights -
#  Use, duplication or disclosure restricted by
#  GSA ADP Schedule Contract with IBM Corp.
#################################################

require 'chef/knife/hmc_base'


class Chef
  class Knife
    class HmcServerCreate < Knife

      include Knife::HmcBase

      deps do
        require 'net/scp'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife hmc server create (options)"

      option :nim_host,
        :short => "-n HOST",
        :long => "--nim_host HOST",
        :description => "The fully qualified domain name of the NIM server"

      option :nim_username,
        :short => "-k USER",
        :long => "--nim_user USER",
        :description => "The username for the NIM server"

      option :nim_password,
        :short => "-m PASSWORD",
        :long => "--nim_pass PASSWORD",
        :description => "The password of the user specified in --nim_user"

      option :image,
        :short => "-I IMAGE",
        :long  => "--image image",
        :description => "The name of the mksysb image on the NIM."

      option :fb_script,
        :short => "-d NAME",
        :long => "--fb_script NAME",
        :description => "Name of the first boot script to use."

      option :ip_address,
        :short => "-i IPADDRESS",
        :long => "--ip_address IPADDRESS",
        :description => "The IP address to use on the LPAR."

      option :vlan_id,
        :short => "-N VLANID",
        :long => "--vlan_id VLANID",
        :description => "The VLAN ID number the NIC on the LPAR should use. --ip_address should reside in this VLAN."

      option :frame_name,
        :short => "-f NAME",
        :long => "--frame NAME",
        :description => "Name of the Host in which the LPAR resides."

      option :lpar_name,
        :short => "-l NAME",
        :long => "--lpar",
        :description => "Name of LPAR you wish to delete."

      option :vio1_name,
        :short => "-p NAME",
        :long => "--primary_vio NAME",
        :description => "Name of the primary vio."

      option :vio2_name,
        :short => "-s NAME",
        :long => "--secondary_vio NAME",
        :description => "Name of the secondary vio."

      option :min_proc,
        :short => "-a PROCVAL",
        :long => "--min_proc PROCVAL",
        :description => "Minimum Processor Units to use on LPAR."

      option :des_proc,
        :short => "-b PROCVAL",
        :long => "--des_proc PROCVAL",
        :description => "Desired Processor Units to use on LPAR."

      option :max_proc,
        :short => "-c PROCVAL",
        :long => "--max_proc PROCVAL",
        :description => "Maximum Processor Units to use on LPAR."  

      option :min_vcpu,
        :short => "-A PROCVAL",
        :long => "--min_vcpu PROCVAL",
        :description => "Minimum virtual CPU to use on LPAR."

      option :des_vcpu,
        :short => "-B PROCVAL",
        :long => "--des_vcpu PROCVAL",
        :description => "Desired virtual CPU to use on LPAR."

      option :max_vcpu,
        :short => "-C PROCVAL",
        :long => "--max_vcpu PROCVAL",
        :description => "Maximum virtual CPU to use on LPAR."  

      option :min_mem,
        :short => "-D PROCVAL",
        :long => "--min_mem PROCVAL",
        :description => "Minimum memory to use on LPAR."

      option :des_mem,
        :short => "-E PROCVAL",
        :long => "--des_mem PROCVAL",
        :description => "Desired memory to use on LPAR."

      option :max_mem,
        :short => "-F PROCVAL",
        :long => "--max_mem PROCVAL",
        :description => "Maximum memory to use on LPAR."  

      option :size,
        :short => "-S SIZEINGB",
        :long => "--size SIZEINGB",
        :description => "Size in GB of the LUN to use for the rootvg."

      option :register_node,
        :short => "-r CHEF_SERVER_URL",
        :long => "--register_node CHEF_SERVER_URL",
        :description => "Bootstraps this server as a Chef node and registers it with the specified Chef server"

      option :bootstrap_user,
        :short => "-u BOOTSTRAP_USER",
        :long => "--bootstrap_user BOOTSTRAP_USER",
        :description => "User to bootstrap the Chef Node as (if not specified, assumed to be 'root'). Completely ignored if --register_node isn't used"

      option :bootstrap_pass,
        :short => "-w BOOTSTRAP_PASS",
        :long => "--bootstrap_pass BOOTSTRAP_PASS",
        :description => "Password to use on the client LPAR when bootstrapping it. Ignored if --register_node is not specified"
      

      def run
     		Chef::Log.debug("Creating server...")

     		validate!([:frame_name,:lpar_name,:vio1_name,:vio2_name,:des_mem,:des_vcpu,:des_proc])
        #Create Objects
     		hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username), {:password => get_config(:hmc_password)}) 
        vio1 = Vio.new(hmc, get_config(:frame_name), get_config(:vio1_name))
        vio2 = Vio.new(hmc, get_config(:frame_name), get_config(:vio2_name))

        #Option checking for LPAR and NIM objects
        #Since we only technically need desired proc,vcpu, mem to make an lpar we
        #need to check for the optional flags. And Deploying the OS is optional we
        #also need to check for those.
        if validate([:min_mem,:max_mem,:min_vcpu,:max_vcpu,:min_proc,:max_proc])
          lpar = Lpar.new({:hmc => hmc,:min_proc => get_config(:min_proc),:des_proc => get_config(:des_proc), :max_proc => get_config(:max_proc), :min_mem => get_config(:min_mem), :des_mem => get_config(:des_mem), :max_mem => get_config(:max_mem), :min_vcpu =>  get_config(:min_vcpu), :des_vcpu => get_config(:des_vcpu), :max_vcpu => get_config(:max_vcpu), :frame => get_config(:frame_name), :name => get_config(:lpar_name)})
        else
          lpar = Lpar.new({:hmc => hmc,:des_proc => get_config(:des_proc),:des_mem => get_config(:des_mem),:des_vcpu => get_config(:des_vcpu), :frame => get_config(:frame_name), :name => get_config(:lpar_name)})
        end

        image_deploy = false
        first_bootscript = nil
        if validate([:nim_host,:nim_username,:nim_password,:image,:ip_address,:size,:vlan_id])
          image_deploy = true
          nim = Nim.new(get_config(:nim_host),get_config(:nim_username), {:password => get_config(:nim_password)})
        end

        if image_deploy == true
          if validate([:fb_script])
            first_bootscript = get_config(:fb_script)
          end
        end

        #Open connections
        hmc.connect
        puts "Connected to #{get_config(:hmc_host)} as #{get_config(:hmc_username)}."
        if image_deploy == true
          nim.connect
          puts "Connected to #{get_config(:nim_host)} as #{get_config(:nim_username)}."
        end

        #Create LPAR
        lpar.create
        puts "LPAR created."

        if image_deploy == true
          #Add vSCSI adapters
          lpar.add_vscsi(vio1)
          lpar.add_vscsi(vio2)
          puts "vSCSI Adapters added to #{get_config(:lpar_name)}."

          #Get vSCSI information
          lpar_vscsi = lpar.get_vscsi_adapters

          #Find the vHosts
          #TO-DO: Need to update the logic here. 1st element doesn't necessarily
          #have to map to the 1st VIO's vSCSI.
          first_vhost = vio1.find_vhost_given_virtual_slot(lpar_vscsi[0].remote_slot_num)
          second_vhost = vio2.find_vhost_given_virtual_slot(lpar_vscsi[1].remote_slot_num)

          #Attach a Disk
          vio1.map_single_disk_by_size(first_vhost,vio2,second_vhost,get_config(:size).to_i)
          puts "LUN attached to #{get_config(:lpar_name)}."

          #Attach vNIC, will activate and deactive LPAR to assign MAC address to NIC
          lpar.create_vnic(get_config(:vlan_id))
          puts "vNIC attached to #{get_config(:lpar_name)}."

          ##Deploy Mksysb, booting LPAR
          nim.deploy_image(lpar,get_config(:image),first_bootscript) do |nimIp,gw,snm| 
             hmc.lpar_net_boot(nimIp,get_config(:ip_address),gw,snm,lpar)
          end
          puts "#{get_config(:image)} deployed to #{get_config(:lpar_name)}."
        end       	
        
        if image_deploy == true
          nim.disconnect
          puts "Disconnected from #{get_config(:nim_host)}."

          #Check to see if the :register_node option has been specified
          #since we can only connect to bootstrap this server if it has
          #a working OS on it.
          if validate([:register_node])
            #Branch here in case we can use Chef::Knife::Bootstrap
            #to handle this sometime in the future. For now, hardcode the
            #manual bootstrap
            manual_bootstrap = true

            #Wait here until the client is alive
            print "Bootstrapping client. Waiting for sshd..."
            print "." until tcp_ssh_alive(get_config(:ip_address))
            puts "done\nInitiating bootstrap."

            if manual_bootstrap
              manual_bootstrap_for_node
            else
              bootstrap_for_node
            end
          end
        end

        #Close connection 
        hmc.disconnect
        puts "Disconnected from #{get_config(:hmc_host)}."

        puts "Successfully created #{get_config(:lpar_name)}."
      end

      #Manually execute the Chef bootstrap of an AIX server
      def manual_bootstrap_for_node
        validate!([:bootstrap_pass])

        #Where the validation pem and chef-client exist on
        #the chef workstation this is run from
        validation_pem_path = Chef::Config[:validation_key]
        puts "Using client key #{validation_pem_path}"
        chef_client_path = Chef::Config[:knife][:chef_client_aix_path]
        puts "Using chef-client located in #{chef_client_path}"

        if validation_pem_path.nil? or chef_client_path.nil?
          puts "No client validation pem or chef-client installable specified in knife.rb. Skipping Chef Bootstrap..."
          return nil
        end

        #Where to place these files on the target server
        remote_chef_client_path = "/tmp/2014-02-06-chef.11.10.0.0.bff"
        remote_validation_pem_path = "/etc/chef/validation.pem"

        #For some reason, Net::SSH and Net::SCP only work on
        #AIX using :kex => "diffie-hellman-group1-sha1" and
        # :encryption => ["blowfish-cbc", "3des-cbc"]
        # :paranoid => false (avoids host key verification)
        Net::SSH.start(get_config(:ip_address), 
                       get_config(:bootstrap_user) || "root", 
                       :password => get_config(:bootstrap_pass), 
                       :kex => "diffie-hellman-group1-sha1",
                       :encryption => ["blowfish-cbc", "3des-cbc"],
                       :paranoid => false) do |ssh|     

          #Copy the chef-client .bff file to the client machine in /tmp
          puts "Copying chef client binary to client"
          ssh.scp.upload!(chef_client_path, remote_chef_client_path)

          #Run the install command
          puts "Running chef client install"
          output = ssh.exec!("installp -aYFq -d #{remote_chef_client_path} chef")
          Chef::Log.debug("Chef Client install output:\n#{output}")

          #Run the configure client command
          puts "Running knife configure client command"
          output = ssh.exec!("knife configure client -s #{get_config(:register_node)} /etc/chef")
          Chef::Log.debug("Knife Configure output:\n#{output}")

          #Copy the validation key to /etc/chef on the client
          puts "Uploading validation.pem to client"
          ssh.scp.upload!(validation_pem_path, remote_validation_pem_path)

          #Edit /etc/chef/client.rb so that it points at the location of the validator
          puts "Adding validator key path to client.rb"
          cmd = %Q{echo "validator_key '#{remote_validation_pem_path}'" >> /etc/chef/client.rb}
          output = ssh.exec!(cmd)
          Chef::Log.debug("#{output}")

          #Register the client node with the Chef server, by running chef-client
          #Add additional handling of this command to determine if the chef-client
          #run finished successfully or not.
          puts "Running chef-client to register as a Chef node"
          output = ""
          stderr_out = ""
          exit_code = nil
          ssh.exec("chef-client") do |ch, success|
            unless success
              abort "FAILED: chef-client command failed to execute on client"
            end
            ch.on_data do |ch,data|
              output+=data
            end
            ch.on_extended_data do |ch,type,data|
              stderr_out+=data
            end
            ch.on_request("exit-status") do |ch,data|
              exit_code = data.read_long
            end
          end
          ssh.loop
          if exit_code != 0
            puts "Initial chef-client run failed. Please verify client settings and rerun chef-client to register this server as a node with #{get_config(:register_node)}"
            return nil
          end
          Chef::Log.debug("chef-client command output:\n#{output}")
        end
      end

      #Bootstrapping a Chef node using all Chef faculties
      #TO-DO: fix up the body of this once normal bootstrap
      #works on AIX nodes.
      def bootstrap_for_node
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [config[:fqdn]]
        bootstrap.config[:run_list] = get_config(:run_list).split(/[\s,]+/)
        bootstrap.config[:secret_file] = get_config(:secret_file)
        bootstrap.config[:hint] = get_config(:hint)
        bootstrap.config[:ssh_user] = get_config(:ssh_user)
        bootstrap.config[:ssh_password] = get_config(:ssh_password)
        bootstrap.config[:ssh_port] = get_config(:ssh_port)
        bootstrap.config[:identity_file] = get_config(:identity_file)
        bootstrap.config[:chef_node_name] = get_config(:chef_node_name)
        bootstrap.config[:prerelease] = get_config(:prerelease)
        bootstrap.config[:bootstrap_version] = get_config(:bootstrap_version)
        bootstrap.config[:distro] = get_config(:distro)
        bootstrap.config[:use_sudo] = true unless get_config(:ssh_user) == 'root'
        bootstrap.config[:template_file] = get_config(:template_file)
        bootstrap.config[:environment] = get_config(:environment)
        bootstrap.config[:first_boot_attributes] = get_config(:first_boot_attributes)
        bootstrap.config[:log_level] = get_config(:log_level)
        # may be needed for vpc_mode
        bootstrap.config[:no_host_key_verify] = get_config(:no_host_key_verify)
        bootstrap
      end

    end
  end
end
