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

      def run
     		Chef::Log.debug("Creating server...")

     		validate!

     		#
     		# Sample code to connect to hmc before running any commands
     		#

    		# servers = connection.servers.all
    		# server = connection.servers.create(server_def_params)

     		# hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        # hmc.connect

       	# TODO: Make the call here...

        # hmc.disconnect

      end

    end
  end
end
