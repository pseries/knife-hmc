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
    class HmcServerConfig < Knife

      include Knife::HmcBase

      banner "knife hmc server config -f FRAME -l LPARNAME -a A=V[,A=V,A=V...]"

      option :lpar,
             :short => "-l LPARNAME",
             :long => "--lpar LPARNAME",
             :description => "The name of the LPAR to configure"

      option :frame,
             :short => "-f FRAME",
             :long => "--frame FRAME",
             :description => "The name of the frame on which the LPAR resides"

      option :attributes,
             :short => "-a A=V[,A=V,...]",
             :long => "--attributes Attr=Value[,Attr=Value,...]",
             :description => "A list of LPAR attributes and what their values should be changed to",
             :proc => Proc.new { |attributes| attributes.split(',') }

      def run
   		  Chef::Log.debug("Configuring server...")

        validate!
        validate!([:lpar,:frame, :attributes])
        hmc = Hmc.new(get_config(:hmc_host), get_config(:hmc_username) , {:password => get_config(:hmc_password)}) 
        hmc.connect

        options_hash = hmc.get_lpar_options(get_config(:frame),get_config(:lpar))
        lpar = Lpar.new(options_hash)

        puts "Configuring #{lpar.name}..."

        attrs = get_config(:attributes)
        attrs.each do |operation|
          key,value = operation.split('=')
          case key
          when "name"
            old_name = lpar.name
            lpar.rename(value)
            puts "Changed name from #{old_name} to #{lpar.name}"
          when "max_virtual_slots"
            old_max = lpar.max_virtual_slots
            lpar.max_virtual_slots = value.to_i
            puts "Changed max_virtual_slots from #{old_max} to #{lpar.max_virtual_slots}"
          when "uncap_weight"
            old_weight = lpar.uncap_weight
            unless (lpar.uncap_weight = value.to_i).nil?
              puts "Changed uncap_weight from #{old_weight} to #{lpar.uncap_weight}"
            end
          when "desired_proc_units"
            old_units = lpar.desired_proc_units
            lpar.desired_proc_units = value.to_f
            puts "Changed desired_proc_units from #{old_units} to #{lpar.desired_proc_units}"
          when "max_proc_units"
            old_units = lpar.max_proc_units
            lpar.max_proc_units = value.to_f
            puts "Changed max_proc_units from #{old_units} to #{lpar.max_proc_units}"
          when "min_proc_units"
            old_units = lpar.min_proc_units
            lpar.min_proc_units = value.to_f
            puts "Changed min_proc_units from #{old_units} to #{lpar.min_proc_units}"
          when "desired_vcpu"
            old_units = lpar.desired_vcpu
            lpar.desired_vcpu = value.to_i
            puts "Changed desired_vcpu from #{old_units} to #{lpar.desired_vcpu}"
          when "max_vcpu"
            old_units = lpar.max_vcpu
            lpar.max_vcpu = value.to_i
            puts "Changed max_vcpu from #{old_units} to #{lpar.max_vcpu}"
          when "min_vcpu"
            old_units = lpar.min_vcpu
            lpar.min_vcpu = value.to_i
            puts "Changed min_vcpu from #{old_units} to #{lpar.min_vcpu}"
          when "desired_memory"
            old_units = lpar.desired_memory
            lpar.desired_memory = value.to_i
            puts "Changed desired_memory from #{old_units} to #{lpar.desired_memory}"
          when "max_memory"
            old_units = lpar.max_memory
            lpar.max_memory = value.to_i
            puts "Changed max_memory from #{old_units} to #{lpar.max_memory}"
          when "min_memory"
            old_units = lpar.min_memory
            lpar.min_memory = value.to_i
            puts "Changed min_memory from #{old_units} to #{lpar.min_memory}"
          else
            puts "Unrecognized attribute #{key}, proceeding to next config change..."
          end
        end

        hmc.disconnect
      end

    end
  end
end
