module Kontena
  class AcmeWorker
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :email, :domains

    ACME_RESPONSE = "/etc/acmetool/response-file.yml"
    ACME_CMD = "acmetool --batch --response-file=#{ACME_RESPONSE}"
    ACME_CERT_DIR = "/var/lib/acme/live/"

    # @param [String] email
    # @param [Array<String>] domains
    # @param [Boolean] autostart
    def initialize(email, domains, autostart = true)
      @domains = domains
      File.open(ACME_RESPONSE, 'a') do |f|
        f.puts('"acme-enter-email": "%s"' % [email])
      end
      async.start! if autostart
    end

    def start!
      defer {
        domains.each{|d|
          want_domain(d)
          copy_domain_cert(d)
        }
        publish 'haproxy:config_updated'
        loop do
          sleep (60*60*24*7) # week
          reconcile_domains
          publish 'haproxy:config_updated'
        end
      }
    end

    # @param [String] domain
    # @return [Boolean]
    def want_domain(domain)
      retries = 0
      begin
        success = system("#{ACME_CMD} want #{domain}")
        if success
          info "fetched cert for domain #{domain}"
        else
          retries += 1
          raise "failed to fetch cert for domain #{domain}"
        end
      rescue => exc
        info exc.message
        wait = 10 * retries
        info "retrying in #{wait} seconds"
        sleep wait
        retry
      end
    end

    # @param [String] domain
    def copy_domain_cert(domain)
      dir = "#{ACME_CERT_DIR}/#{domain}/"
      dest = "/etc/ssl/private/#{domain}.pem"
      if File.exist?(File.join(dir, 'fullchain')) && File.exist?(File.join(dir, 'privkey'))
        info "copying #{domain} certificate"
        cert = File.read(File.join(dir, 'fullchain'))
        cert << "\n"
        cert << File.read(File.join(dir, 'privkey'))
        File.open(dest, 'w') do |f|
          f.puts cert
        end
      elsif File.exist?(dest)
        File.unlink(dest)
        info "removing certificate from #{domain}"
      end
    end

    # @return [Boolean]
    def reconcile_domains
      system("#{ACME_CMD} reconcile")
    end
  end
end
