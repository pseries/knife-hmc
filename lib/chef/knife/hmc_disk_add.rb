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
    class HmcDiskAdd < Knife

      include Knife::HmcBase

      banner "knife hmc disk add (options)"

      option :frame_name,
        :short => "-f NAME",
        :long => "--frame_name NAME",
        :description => "Name of the Host in which the LPAR resides."

      option :lpar_name,
        :short => "-l NAME",
        :long => "--lpar_name",
        :description => "Name of LPAR you wish to delete."

      option :vio1_name,
        :short => "-p NAME",
        :long => "--primary_vio NAME",
        :description => "Name of the primary vio."

      option :vio2_name,
        :short => "-s NAME",
        :long => "--secondary_vio NAME",
        :description => "Name of the secondary vio."  

      option :size,
        :short => "-S SIZE",
        :long => "--size_in_GB SIZE",
        :description => "The size in GB you require, will find the size requested or larger."

      option :volume_group,
        :short => "-g NAME",
        :long => "--volume_group NAME",
        :description => "Name of volume group disk will be used in. If rootvg is passed then script will find a single LUN vs multiple smaller luns to fit request."

      def run
   		  Chef::Log.debug("Adding disk...")

        validate!([:frame_name,:lpar_name,:vio2_name,:vio1_name,:size])

        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect

        #Populate hash to make LPAR object
        lpar_hash = hmc.get_lpar_options(get_config(:frame_name),get_config(:lpar_name))
        #Create LPAR object based on hash, and VIO objects
        lpar = Lpar.new(lpar_hash)
        vio1 = Vio.new(hmc, get_config(:frame_name), get_config(:vio1_name))
        vio2 = Vio.new(hmc, get_config(:frame_name), get_config(:vio2_name))

        #Get vSCSI Information
        lpar_vscsi = lpar.get_vscsi_adapters
        first_vhost = nil
        second_vhost = nil
        adapter_cnt = 0
        if lpar_vscsi.empty? == true
          #Add vSCSI Adapters
          lpar.add_vscsi(vio1)
          lpar.add_vscsi(vio2)
        else
          lpar_vscsi.each do |adapter|
            if adapter.remote_lpar_name == vio1.Name
              first_vhost = adapter.remote_slot_num
              adapter_cnt += 1
            elsif adapter.remote_lpar_name == vio2.Name
              second_vhost = adapter.remote_slot_num
              adapter_cnt += 1
            end
          end 
          if first_vhost.nil? or second_vhost.nil? or adapter_cnt != 2
            #vSCSIs not linked to VIOs specified adding new ones
            lpar.add_vscsi(vio1)
            lpar.add_vscsi(vio2)
            lpar_vscsi = lpar.get_vscsi_adapters
            #Find the vHosts
            first_vhost = vio1.find_vhost_given_virtual_slot(lpar_vscsi[0].remote_slot_num)
            second_vhost = vio2.find_vhost_given_virtual_slot(lpar_vscsi[1].remote_slot_num)
          end
          if validate([:volume_group])
            if get_config(:volume_group).to_s.downcase == "rootvg"
              vio1.map_single_disk_by_size(first_vhost,vio2,second_vhost,get_config(:size).to_i)        
            else
              vio1.map_by_size(first_vhost,vio2,second_vhost,get_config(:size).to_i)
            end
          else
            vio1.map_by_size(first_vhost,vio2,second_vhost,get_config(:size).to_i)
          end
        end
        hmc.disconnect        
      end
    end
  end
end
