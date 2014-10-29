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
    class HmcImageList < Knife

      include Knife::HmcBase

      banner "knife hmc image list --nim_host HOSTNAME --nim_user USER --nim_pass PASSWORD"

      option :nim_host,
             :short => "-n HOST",
             :long => "--nim_host HOST",
             :description => "The fully qualified domain name of the NIM server"

      option :nim_user,
             :short => "-l USER",
             :long => "--nim_user USER",
             :description => "The username for the NIM server"


      option :nim_pass,
             :short => "-m PASSWORD",
             :long => "--nim_pass PASSWORD",
             :description => "The password of the user specified in --nim_user"
                 

      def run
        Chef::Log.debug("Listing images...")

        validate!([:nim_host,:nim_user,:nim_pass])        

        nim = Nim.new(get_config(:nim_host),get_config(:nim_user),{:password => get_config(:nim_pass)})
        nim.connect

        puts "Mksysb Image Names: "
        nim.list_images.each do |image_name|
          puts "#{image_name}"
        end
        
        nim.disconnect
      end

    end
  end
end
