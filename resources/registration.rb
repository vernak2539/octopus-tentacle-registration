include OcotopusDeploy::SshTentacleRegistration

resource_name :register_ssh_octopus_tenacle

actions :create
default_action :create

property :server_url, String, name_property: true, required: true
property :api_key, String, name_property: true, required: true
property :ssh_account_id, String, name_property: true, required: true
property :environments, Array, name_property: true, required: true
property :roles, Array, name_property: true, required: true
property :dotnet_core_platform, String, required: false, default: ''

OCTOPUS_DIRECTORY = '/opt/octopus'.freeze
MACHINE_ID_FILE = "#{OCTOPUS_DIRECTORY}/machine_id".freeze

action :create do
  require 'json'

  machine_id = tentacle_machine_id(machine_id_file_location)
  if(machine_id.instance_of? String)
    log 'inform' do
      message "Machine has already been registered with ID of '#{machine_id}'"
      level :info
    end
    return
  end

  machine_data = {
    url: register_ssh_octopus_tenacle.server_url,
    api_key: register_ssh_octopus_tenacle.api_key,
    ssh_account_id: register_ssh_octopus_tenacle.ssh_account_id,
    fingerprint: generateFingerPrint(),
    roles: register_ssh_octopus_tenacle.roles,
    environments: register_ssh_octopus_tenacle.environments,
    node: {
      ipaddress: node['ipaddress'],
      machinename: node['machinename'].upcase
    }
  }

  if(register_ssh_octopus_tenacle.dotnet_core_platform != '')
    machine_data['dotnet_core_platform'] = register_ssh_octopus_tenacle.dotnet_core_platform
  end

  machine = register_machine(machine_data)

  machine_id = machine[:id]

  if(machine_id)
    directory OCTOPUS_DIRECTORY do
      recursive true
    end

    file MACHINE_ID_FILE do
      content machine_id
    end

    log 'successful registration' do
      message "Registered machine on octopus server with ID of '#{machine_id}'"
      level :info
    end
  else
    Chef::Log.error('Unsuccessful registration')
    Chef::Log.error("Request Data: #{machine[:post_data]}")
    Chef::Log.error("Response: #{machine[:response]}")
  end


end
