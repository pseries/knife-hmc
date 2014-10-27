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

require 'knife-hmc/version'

class Chef
  class Knife
    module HmcBase
    	
	  # :nodoc:
      #####################################################
      #  included
      #####################################################
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'chef/json_compat'
            require 'chef/knife'
            require 'readline'
            #require 'remote_hmc'
			Chef::Knife.load_deps
          end

          option :hmc_host,
                 :short => "-h HOST",
                 :long => "--host HOST",
                 :description => "The fully qualified domain name of the HMC host",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_host] = key }

          option :hmc_username,
                 :short => "-U USERNAME",
                 :long => "--userid USERNAME",
                 :description => "The username for the HMC",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_username] = key }

          option :hmc_password,
                 :short => "-P PASSWORD",
                 :long => "--password PASSWORD",
                 :description => "The password for hmc",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_password] = key }

        end
      end

      #####################################################
      #  validate
      #####################################################
      def validate!(keys=[:hmc_host, :hmc_username, :hmc_password])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provided a valid '#{pretty_key}' value."
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

      #####################################################
      #  get config
      #####################################################
      def get_config(key)
        key = key.to_sym
        rval = config[key] || Chef::Config[:knife][key] || $default[key]
        Chef::Log.debug("value for config item #{key}: #{rval}")
        rval
      end

	end
  end
end
