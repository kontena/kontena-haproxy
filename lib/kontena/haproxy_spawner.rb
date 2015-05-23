
module Kontena
  class HaproxySpawner
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    ##
    # @param [String] config_file
    def initialize(haproxy_bin = '/usr/sbin/haproxy', config_file = '/etc/haproxy/haproxy.cfg')
      @current_pid = nil
      @haproxy_cmd = [haproxy_bin, '-f', config_file, '-db']
      subscribe 'haproxy:config_updated', :update_haproxy
    end

    def update_haproxy(*args)
      if current_pid
        reload_haproxy
      else
        start_haproxy
      end
    end

    def start_haproxy
      info 'Starting HAProxy process'
      @current_pid = Process.spawn(@haproxy_cmd.join(' '))
    end

    def reload_haproxy
      info 'Reloading haproxy'
      reload_cmd = @haproxy_cmd + ['-sf', @current_pid.to_s]
      pid = Process.spawn(reload_cmd.join(' '))
      Process.wait(@current_pid)
      @current_pid = pid
    end

    private

    def current_pid
      @current_pid
    end
  end
end
