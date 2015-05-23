
module Kontena
  class BackendResolver
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :interval, :backends, :dns_resolver

    def initialize(opts)
      @interval = opts[:interval].to_i
      @backends = opts[:backends]
      @dns_resolver = Celluloid::IO::DNSResolver.new
    end

    def start!
      info "Starting to resolve ip's for backends: #{self.backends}"
      info "with interval of #{self.interval} seconds"
      loop do
        resolve_backends
        sleep self.interval
      end
    end

    def resolve_backends
      resolved_backends = {}
      self.backends.each do |backend|
        service, port = backend.split(':')
        resolved_ips = resolve_dns(service)
        debug resolved_ips
        if resolved_ips
          resolved_backends[service] = resolved_ips.map{|r|
            { ip: r.to_s, port: port }
          }
        end
      end
      publish 'backends_resolved', resolved_backends
    rescue => exc
      error "Failed to resolve backends: #{exc.message}"
    end

    ##
    # @param [String] dns_name
    # @return [Array<Resolv::IPv4>]
    def resolve_dns(dns_name)
      resolved = dns_resolver.resolve(dns_name)
      if resolved.is_a?(Resolv::IPv4)
        [resolved]
      else
        resolved
      end
    end
  end
end
