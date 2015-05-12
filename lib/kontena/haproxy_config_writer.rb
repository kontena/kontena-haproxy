module Kontena
  class HaproxyConfigWriter
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_accessor :config_file

    ##
    # @param [String] config_file
    def initialize(config_file = '/etc/haproxy/haproxy.cfg')
      self.config_file = config_file
      @old_config = ''
      subscribe 'haproxy:config_generated', :update_config
    end

    ##
    # @param [String] topic
    # @param [String] config
    def update_config(topic, config)
      if @old_config != config
        info config
        write_config(config)
        @old_config = config
        publish 'haproxy:config_updated'
      end
    end

    ##
    # @param [String] config
    def write_config(config)
      File.write(config_file, config.to_s)
    end
  end
end
