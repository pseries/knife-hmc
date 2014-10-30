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
        :short => "-f NAME",
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
          lpar = Lpar.new({hmc,:min_proc => get_config(:min_proc),:des_proc => get_config(:des_proc), :max_proc => get_config(:max_proc), :min_mem => get_config(:min_mem), :des_mem => get_config(:des_mem), :max_mem => get_config(:max_mem), :min_vcpu =>  get_config(:min_vcpu), :des_vcpu => get_config(:des_vcpu), :max_vcpu => get_config(:max_vcpu), :frame => get_config(:frame_name), :name => get_config(:lpar_name)})
        else
          lpar = Lpar.new({hmc,:des_proc => get_config(:des_proc),:des_mem => get_config(:des_mem),:des_vcpu => get_config(:des_vcpu), :frame => get_config(:frame_name), :name => get_config(:lpar_name)})
        end

        image_deploy = false
        first_bootscript = nil
        if validate([:nim_host,:nim_username,:nim_password,:image,:ip_address,:size,:vlan_id])
          image_deploy = true
          nim = Nim.new(get_config(:nim_host,get_config(:nim_username), {:password => get_config(:nim_password)})
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
          lpar_vscsi = lpar.get_vscsi adapters

          #Find the vHosts
          first_vhost = vio1.find_vhost_given_virtual_slot(lpar_vscsi[0].remote_slot_num)
          second_vhost = vio2.find_vhost_given_virtual_slot(lpar_vscsi[1].remote_slot_num)

          #Attach a Disk
          vio1.map_single_disk_by_size(first_vhost,vio2,second_vhost,get_config(:size))
          puts "LUN attached to #{get_config(:lpar_name)}."

          #Attach vNIC, will activate and deactive LPAR to assign MAC address to NIC
          lpar.create_vnic(get_config(:vlan_id))
          puts "vNIC attached to #{get_config(:lpar_name)}."

          ##Deploy Mksysb, booting LPAR
          nim.deploy_image(lpar,get_config(:image),first_bootscript) do |nimIp,gw,snm| 
             hmc.lpar_net_boot(nimIp,get_config(:ip_address,gw,snm,lpar)
          end
          puts "#{get_config(:image)} deployed to #{get_config(:lpar_name)}."
        end
       	
        #Close connection 
        hmc.disconnect
        puts "Disconnected from #{get_config(:hmc_host)}."
        if image_deploy == true
          nim.disconnect
          puts "Disconnected from #{get_config(:nim_host)}."
        end
        puts "Successfully created #{get_config(:lpar_name)}."
      end
    end
  end
end
