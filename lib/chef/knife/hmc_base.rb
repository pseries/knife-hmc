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
            require 'rbvppc'
            require 'netaddr'
            Chef::Knife.load_deps
          end

          option :hmc_host,
                 :short => "-h HOST",
                 :long => "--hmc_host HOST",
                 :description => "The fully qualified domain name of the HMC host",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_host] = key }

          option :hmc_username,
                 :short => "-U USERNAME",
                 :long => "--hmc_user USERNAME",
                 :description => "The username for the HMC",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_username] = key }

          option :hmc_password,
                 :short => "-P PASSWORD",
                 :long => "--hmc_pass PASSWORD",
                 :description => "The password for hmc",
                 :proc => Proc.new { |key| Chef::Config[:knife][:hmc_password] = key }

        end
      end

      #####################################################
      #  tcp_ssh_alive
      #  Returns true if the hostname specified is
      #  accepting SSH connections. Returns false otherwise
      #####################################################
      def tcp_ssh_alive(hostname,port=22)
        tcp_socket = TCPSocket.new(hostname, port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          true
        else
          false
        end
        
        rescue Errno::ETIMEDOUT
          false
        rescue Errno::EPERM
          false
        rescue Errno::ECONNREFUSED
          sleep 2
          false
        rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH
          sleep 2
          false
        ensure
          tcp_socket && tcp_socket.close
      end

      #####################################################
      #  validate!
      #####################################################
      def validate!(keys=[:hmc_host, :hmc_username, :hmc_password])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil? and config[k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

      #####################################################
      #  validate - no exit on errors
      #####################################################
      def validate(keys)
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil? and config[k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end

        if errors.empty?
          return true
        else
          return false
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
