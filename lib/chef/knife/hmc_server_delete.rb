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
    class HmcServerDelete < Knife

      include Knife::HmcBase

      banner "knife hmc server delete SERVER (options)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the OpenStack node itself. Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name. Only has meaning when used with the '--purge' option."

      option :hmc_host,
        :short => "-h HOST",
        :long => "--hmc_host HOST",
        :description => "The fully qualified domain name of the HMC."  

      option :hmc_username,
        :shot => "-u USERNAME",
        :long => "--hmc_username USERNAME",
        :description => "The user name to use on the HMC, preferably hscroot."

      option :hmc_password,
        :short => "-p PASSWORD",
        :long  => "--hmc_password PASSWORD",
        :description => "The password of the user provided in the :hmc_username option."
        
      def run
   		Chef::Log.debug("Deleting server...")

        validate!([:hmc_host,:hmc_username,:hmc_password])
       
        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect
        lpar_hash = hmc.get_lpar_options(get_config(:frame_name),get_config(:lpar_name))
        lpar = Lpar.new(lpar_hash)
        vio1 = Vio.new(hmc, get_config(:frame_name), get_config(:vio1_name))
        vio2 = Vio.new(hmc, get_config(:frame_name), get_config(:vio2_name))
        lpar.delete([vio1,vio2])
        hmc.disconnect

      end

    end
  end
end
