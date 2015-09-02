#
# Authors: Christopher M Wood (<woodc@us.ibm.com>)
#          John F Hutchinson (<jfhutchi@us.ibm.com>) 
# © Copyright IBM Corporation 2015.
#
# LICENSE: MIT (http://opensource.org/licenses/MIT)
# 
require 'chef/knife/hmc_base'

class Chef
  class Knife
    class HmcServerList < Knife

      include Knife::HmcBase

      banner "knife hmc server list [--frame FRAME]"

      option :frame,
             :short => "-f FRAME",
             :long => "--frame FRAME",
             :description => "The name of the frame (as known by the HMC) to list the LPARs of"

      def run
        Chef::Log.debug("Listing servers...")

        validate!

        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect

        #If frame was specified, list only the LPARs on that frame
        if !get_config(:frame).nil?
          validate!([:frame])
          puts "LPARs on frame #{get_config(:frame)}:"
          hmc.list_lpars_on_frame(get_config(:frame)).each do |lpar_name|
            puts "#{lpar_name}"
          end
        else
          #Otherwise, list all of the LPARs on each frame
          #managed by this HMC
          frames = hmc.list_frames
          frames.each do |frame|
            puts "LPARs on frame #{frame}:"
            hmc.list_lpars_on_frame(frame).each do |lpar_name|
              puts "#{lpar_name}"
            end
            puts "\n"
          end
        end
        hmc.disconnect
      end

    end
  end
end
