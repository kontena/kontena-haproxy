require 'celluloid'
require 'celluloid/autostart'
require 'celluloid/io'

require_relative 'kontena/backend_resolver'
require_relative 'kontena/haproxy_config_generator'
require_relative 'kontena/haproxy_config_writer'
require_relative 'kontena/haproxy_spawner'
require_relative 'kontena/acme_worker'
