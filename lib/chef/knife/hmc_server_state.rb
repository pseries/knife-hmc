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
    class HmcServerState < Knife

		include Knife::HmcBase

		banner "knife hmc server state (options)"

		option :lpar_name,
			:short => "-l NAME",
			:long => "--lpar NAME",
			:description => "Name of the LPAR as seen on the HMC Console."

		option :frame_name,
			:short => "-f NAME",
			:long => "--frame NAME",
			:description => "Name of the Host in which the LPAR resides."

		option :power_on,
			:short => "-p",
			:long => "--power_on",
			:boolean => true,
			:description => "Turn the LPAR on."  

		option :power_off_soft,
			:short => "-o",
			:long => "--power_off_soft",
			:boolean => true,
			:description => "Operating System level shutdown.."    

		option :power_off_quick,
			:short => "-q",
			:long  => "--power_off_quick",
			:boolean => true,
			:description => "Instant power off."

   		def run
    		Chef::Log.debug("Changing State...")

   			validate!([:frame_name,:lpar_name])

   			hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        	hmc.connect

       		#Populate hash to make LPAR object
        	lpar_hash = hmc.get_lpar_options(get_config(:frame_name),get_config(:lpar_name))
        	#Create LPAR object based on hash, and VIO objects
        	lpar = Lpar.new(lpar_hash)

        	if validate([:power_on])
        		if lpar.is_running?
        			puts "#{get_config(:lpar_name)} is already running, exiting"   
        			return true    		
        		else
        			lpar.activate
        			puts "Powering on #{get_config(:lpar_name)}."
        		end
        	end

        	if validate([:power_off_soft])
        		lpar.soft_shutdown
        		puts "Shutting down #{get_config(:lpar_name)}."
        	end

        	if validate([:power_off_quick])
        		lpar.hard_shutdown
        		puts "Performing hard power off of #{get_config(:lpar_name)}."
        	end
        	hmc.disconnect
    	end
   	end
  end
end