#
# Authors: Christopher M Wood (<woodc@us.ibm.com>)
#          John F Hutchinson (<jfhutchi@us.ibm.com>) 
# © Copyright IBM Corporation 2015.
#
# LICENSE: MIT (http://opensource.org/licenses/MIT)
# 

require 'chef/knife/hmc_base'

# Needed by the '--purge' deletion option
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class HmcServerDelete < Knife

      include Knife::HmcBase

      banner "knife hmc server delete --frame NAME --lpar NAME --primary_vio NAME --secondary_vio NAME"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the OpenStack node itself. Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node_name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name. Only has meaning when used with the '--purge' option."

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

      #Extracted from Chef::Knife.delete_object.
      #That function requires an extra confirmation before
      #proceeding, which seems overly cautious of an operation
      #that will destroy the server that the node represents.
      def destroy_chef_node(objectClass,name,type)
        object = objectClass.load(name)
        object.destroy
        puts "Deleted #{type} #{name}"
      end

      def run
   		  Chef::Log.debug("Deleting server...")

        validate!([:frame_name,:lpar_name])
       
        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect
        lpar_hash = hmc.get_lpar_options(get_config(:frame_name),get_config(:lpar_name))
        lpar = Lpar.new(lpar_hash)
           
        if get_config(:vio1_name).nil? and get_config(:vio2_name).nil?
          lpar.delete()
          puts "#{get_config(:lpar_name)} destroyed"
        else
          validate!([:vio1_name, :vio2_name])
          vio1 = Vio.new(hmc, get_config(:frame_name), get_config(:vio1_name))
          vio2 = Vio.new(hmc, get_config(:frame_name), get_config(:vio2_name))
          lpar.delete([vio1,vio2])
          puts "#{get_config(:lpar_name)} destroyed"
        end

        Chef::Log.debug("Server #{lpar.name} has been deleted.")

        #If :purge option was specified, delete the Chef node that
        #represents the LPAR we just deleted
        if get_config(:purge)
          Chef::Log.debug("Removing Chef node for #{lpar.name}")
          node_name = get_config(:chef_node_name) || lpar.name
          puts "Removing Chef node for #{lpar.name}"
          destroy_chef_node(Chef::Node, node_name, "node")
          destroy_chef_node(Chef::ApiClient, node_name, "client")
        end

        hmc.disconnect
      end
    end
  end
end
