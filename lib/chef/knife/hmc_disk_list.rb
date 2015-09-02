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
    class HmcDiskList < Knife

      include Knife::HmcBase

      banner "knife hmc disk list -r VIONAME1 -s VIONAME2 -f FRAMENAME [-l LPARNAME | -a | -x]"

      option :primary_vio,
             :short => "-r VIONAME",
             :long => "--primary_vio VIONAME",
             :description => "The LPAR name of the Primary VIO"

      option :secondary_vio,
             :short => "-s VIONAME",
             :long => "--secondary_vio VIONAME",
             :description => "The LPAR name of the Secondary VIO"

      option :frame,
             :short => "-f FRAMENAME",
             :long => "--frame FRAMENAME",
             :description => "The name of the Frame in which the VIOs reside"

      option :lpar,
             :short => "-l LPARNAME",
             :long => "--lpar LPARNAME",
             :description => "The name of the LPAR whose disks should be listed (optional)"

      option :only_available,
             :short => "-a",
             :long => "--available",
             :boolean => true,
             :default => false,
             :description => "List ONLY the available disks in this VIO pair (optional)"

      option :only_used,
             :short => "-x",
             :long => "--used",
             :boolean => true,
             :default => false,
             :description => "List ONLY the used disks in this VIO pair (optional)"


      def run
   		  Chef::Log.debug("Listing disks...")

        validate!
        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect

        validate!([:primary_vio,:secondary_vio,:frame])

        frame = get_config(:frame)
        primary_vio_name = get_config(:primary_vio)
        secondary_vio_name = get_config(:secondary_vio)

        #Make Vio objects for the two VIOs
        primary_vio = Vio.new(hmc,frame,primary_vio_name)
        secondary_vio = Vio.new(hmc,frame,secondary_vio_name)

        #Arrays that will hold the disks to list
        vio1_disks = []
        vio2_disks = []

        if validate([:lpar])
          #Show only disks attached to the specified LPAR
          lpar_name = get_config(:lpar)
          options_hash = hmc.get_lpar_options(frame,lpar_name)
          lpar = Lpar.new(options_hash)

          #Get the vSCSIs from this LPAR and determine the virtual adapter
          #slots used by each VIO
          vscsi_adapters = lpar.get_vscsi_adapters
          primary_vio_slot = nil
          secondary_vio_slot = nil
          adapter_cnt=0
          vscsi_adapters.each do |adapter|
            if adapter.remote_lpar_name == primary_vio.name
              primary_vio_slot = adapter.remote_slot_num
              adapter_cnt += 1
            elsif adapter.remote_lpar_name == secondary_vio.name
              secondary_vio_slot = adapter.remote_slot_num
              adapter_cnt += 1
            end             
          end

          if primary_vio_slot.nil? or secondary_vio_slot.nil? or adapter_cnt != 2
            #Could not determine which vSCSIs to use
            error = "Unable to determine which vSCSI adapters have storage attached to it from #{primary_vio_name} and #{secondary_vio_name}\n" +
                    "Cannot list disks attached to #{lpar_name}"
            puts "#{error}"
            ui.error(error)           
            exit 1            
          end

          #Find the vhosts that hold this LPARs disks
          primary_vhost = primary_vio.find_vhost_given_virtual_slot(primary_vio_slot)
          secondary_vhost = secondary_vio.find_vhost_given_virtual_slot(secondary_vio_slot)

          #Get the names (known to the VIOs) of the disks attached to the LPAR
          vio1_disks = primary_vio.get_attached_disks(primary_vhost)
          vio2_disks = secondary_vio.get_attached_disks(secondary_vhost)        
        elsif get_config(:only_available)
          #Show only available disks
          vio1_disks = primary_vio.available_disks
          vio2_disks = secondary_vio.available_disks
        elsif get_config(:only_used)
          #Show only used disks
          vio1_disks = primary_vio.used_disks
          vio2_disks = secondary_vio.used_disks
        else
          #None of :lpar, :only_available, and :only_used options were specified.
          #Show used *and* available disks
          vio1_disks = primary_vio.available_disks + primary_vio.used_disks
          vio2_disks = secondary_vio.available_disks + secondary_vio.used_disks
        end

        #List the disks populated in vio1_disks and vio2_disks
        print_header

        vio1_disks.each do |v1_disk|
          vio2_disks.each do |v2_disk|
            if v1_disk == v2_disk
              print_line(v1_disk,v2_disk)
            end
          end
        end
        
        hmc.disconnect
        
      end

      ##################################################
      # print_header
      # => Prints table header for disk list
      ##################################################
      def print_header
        if validate([:lpar])
          puts "Listing information on all disks attached to #{get_config(:lpar)}\n"
        elsif get_config(:only_available)
          puts "Listing only available disks on this VIO Pair\n"
        elsif get_config(:only_used)
          puts "Listing only used disks on this VIO Pair\n"
        else
          puts "Listing all disks on this VIO Pair\n"
        end

        printf "%-20s %10s %20s %20s\n", "PVID", "Size (MB)", "Name (on #{get_config(:primary_vio)})", "Name (on #{get_config(:secondary_vio)})"
        printf "-----------------------------------------------------------------------------------------\n"
      end

      ##################################################
      # print_line
      # => Prints a single line of the output table
      #    given two Lun objects representing the same
      #    disk on a pair of VIOs
      ##################################################
      def print_line(vio1_disk,vio2_disk)
        printf "%-20s %10s %20s %20s\n", vio1_disk.pvid, "#{vio1_disk.size_in_mb} MB", vio1_disk.name, vio2_disk.name
      end
    end
  end
end
