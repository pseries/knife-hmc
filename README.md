# Knife::Hmc

A Chef Knife plugin for creating, deleting, bootstrapping, and managing LPARs and P series virtual infrastructure.

## Installation

Add this line to your application's Gemfile:

    gem 'knife-hmc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knife-hmc

## Configuration
Add the path to the chef-client AIX installable on your Chef Server to your `knife.rb` file
to add support for Chef bootstrapping an AIX node as a part of 'knife hmc server create'.

```ruby
log_level                :info
log_location             STDOUT
node_name                'node'
client_key               '/path/to/key.pem'
validation_client_name   'some-validator'
validation_key           '/path/to/validator.pem'
chef_server_url          'https://example.com/organizations/org'
syntax_check_cache_path  '/path/to/syntax_check_cache'
knife[:chef_client_aix_path] = "<CHEF SERVER LOCAL PATH TO AIX BINARY>"
```

## Usage

See `knife hmc SUBCOMMAND --help` for help on usage. Here are subcommands that usage help
can be provided for:

```ruby
knife hmc server create --help
knife hmc server delete --help
knife hmc server config --help
knife hmc server list --help

knife hmc image list --help

knife hmc disk list --help
knife hmc disk add --help
knife hmc disk remove --help
```

EXAMPLES:


```bash
# look at all the LPARs on a frame or in an environment
user@local> knife hmc server list --hmc_host testhmc.us.ibm.com --hmc_user hscroot --hmc_pass passw0rd \
[--frame FRAME]
```

```bash
# LPAR creation and BOS install with the minimum arguments
user@local> knife hmc server create --hmc_host testhmc.us.ibm.com --hmc_user hscroot --hmc_pass passw0rd \
--frame test_frame \
--lpar test_lpar \
--primary_vio test_vio1 \
--secondary_vio test_vio2 \
--des_proc 2.0 \
--des_vcpu 2 \
--des_mem 2048 \
--nim_host testnim.us.ibm.com \
--nim_user root \
--nim_pass passw0rd \
--image image_name \
--ip_address lpar_ip \
--size 90 \
--vlan_id vlan \
--register_node chef_server_url \
--bootstrap_pass passw0rd
```

```bash
# List all of the images that an environment's
# NIM can deploy
user@local> knife hmc image list --nim_host testnim.us.ibm.com --nim_user root --nim_pass passw0rd
```

```bash
# List all of this disks
# that a VIO pair has access to
user@local> knife hmc disk list --hmc_host testhmc.us.ibm.com --hmc_user hscroot --hmc_pass passw0rd \
--primary_vio test_vio_1 \
--secondary_vio test_vio_2 \
--frame test_frame \
[--lpar test_lpar_name | --available | --used]
```

#### Legal stuff
Use of this software requires runtime dependencies.  Those dependencies and their respective software licenses are listed below.

* [net-ssh](https://github.com/net-ssh/net-ssh/) - LICENSE: [MIT](https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt)
* [net-scp](https://github.com/net-ssh/net-scp/) - LICENSE: [MIT](https://github.com/net-ssh/net-scp/blob/master/LICENSE.txt)
