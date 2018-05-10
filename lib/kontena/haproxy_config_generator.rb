module Kontena
  class HaproxyConfigGenerator
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :options, :config, :vhosts

    def initialize(opts)
      @options = opts
      @config = {}
      create_vhosts
      create_default_config
      subscribe 'backends_resolved', :update_config
    end

    def create_default_config
      config['global'] = [
        "maxconn %s" % options[:maxconn],
        "pidfile /var/run/haproxy.pid",
        "user haproxy",
        "group haproxy",
        "daemon",
        "stats socket /var/run/haproxy.stats level admin"
      ]
      config['defaults'] = [
        "mode %s" % options[:mode]
      ]
      if options[:option]
        options[:option].each do |option|
          config['defaults'] << 'option %s' % option.strip
        end
      end
      if options[:timeout]
        options[:timeout].each do |timeout|
          config['defaults'] << 'timeout %s' % timeout.strip
        end
      end
    end

    ##
    # @param [String] topic
    # @param [Hash] backends
    def update_config(topic, backends)
      create_frontend
      create_backend(backends)
      publish('haproxy:config_generated', config_to_string)
    end

    def create_frontend
      frontend = []
      frontend << 'bind 0.0.0.0:%s' % options[:frontend_port]
      if has_certs?
        frontend << 'redirect scheme https code 301 if !{ ssl_fc } !{ url_beg /.well-known/acme-challenge/ }'
        frontend << 'bind 0.0.0.0:443 ssl crt /etc/ssl/private/'
        frontend << 'reqadd X-Forwarded-Proto:\ https'
      end

      frontend << 'acl acme url_beg /.well-known/acme-challenge/'
      frontend << 'use_backend acme if acme'

      if options[:virtual_hosts] != ''
        vhosts.each do |service, domain|
          id = service.downcase.sub('-', '_')
          frontend << 'acl host_%s hdr(host) -i %s' % [id, domain]
          frontend << 'use_backend %s_cluster if host_%s' % [id, id]
        end
      else
        frontend << 'default_backend default_backend'
      end
      config['frontend default_frontend'] = frontend
    end

    ##
    # @param [Hash] backend_services
    def create_backend(backend_services)
      if options[:virtual_hosts] != ''
        create_virtual_host_backends(backend_services)
      else
        create_default_backend(backend_services)
      end

      config['backend acme'] = [
        'server acmetool 127.0.0.1:402'
      ]
    end

    ##
    # @param [Hash] backend_services
    def create_virtual_host_backends(backend_services)
      vhosts.each do |service, domain|
        if backend_services[service]
          backend = []
          backend << 'balance %s' % options[:balance]
          service_name = service.gsub('.', '-')
          i = 1
          backend_services[service].each do |host|
            backend << 'server %s %s:%s' % ["#{service_name}-#{i}", host[:ip], host[:port]]
            i += 1
          end
          id = service.downcase.sub('-', '_')
          config["backend %s_cluster" % id] = backend
        end
      end
    end

    ##
    # @param [Hash] backend_services
    def create_default_backend(backend_services)
      backend = []
      backend << 'balance %s' % options[:balance]
      if options[:health_check_port].empty?
        health_check = ''
      else
        health_check = 'check port %s inter %ss' % [options[:health_check_port], options[:health_check_interval]]
      backend_services.each do |service, hosts|
        service_name = service.gsub('.', '-')
        i = 1
        hosts.each do |host|
          backend << 'server %s %s:%s %s' % ["#{service_name}-#{i}", host[:ip], host[:port], health_check]
          i += 1
        end
      end
      config['backend default_backend'] = backend
    end

    def create_vhosts
      @vhosts = {}
      options[:virtual_hosts].split(',').each do |host|
        service, domain = host.split('=', 2)
        if service && domain
          @vhosts[service.strip] = domain.strip
        end
      end
    end

    ##
    # @return [String]
    def config_to_string
      conf = ''
      config.each do |key, values|
        conf << "#{key}\n"
        values.each do |v|
          conf << "  #{v}\n"
        end
      end
      conf
    end

    # @return [Boolean]
    def has_certs?
      Dir.glob("/etc/ssl/private/*").size > 0
    end
  end
end
