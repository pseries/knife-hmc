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
    class HmcDiskRemove < Knife

      include Knife::HmcBase

      banner "knife hmc disk remove (options)"

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

      option :pvid,
        :short => "-i PVID",
        :long => "--pvid PVID",
        :description => "Physical Volume Identification Number."

      def run
   		  Chef::Log.debug("Removing disk...")

        validate!([:frame_name,:lpar_name,:vio2_name,:vio1_name,:pvid])
        #Create HMC Object and connect to the HMC
        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect
        #Populate hash to make LPAR object
        lpar_hash = hmc.get_lpar_options(get_config(:frame_name),get_config(:lpar_name))
        #Create LPAR object based on hash, and VIO objects
        lpar = Lpar.new(lpar_hash)
        vio1 = Vio.new(hmc, get_config(:frame_name), get_config(:vio1_name))
        vio2 = Vio.new(hmc, get_config(:frame_name), get_config(:vio2_name))
        #Remove disk by pvid
        vio1.unmap_by_pvid(vio2,get_config(:pvid))
        #Disconnect from HMC
        hmc.disconnect
        
      end

    end
  end
end
