require 'awesome_print'

module OmniAuth
  module Strategies
    class CAS
      class Configuration

        def initialize( config )
          @config = config

          validate_cas_setup
        end

        def validate_cas_setup
          if @config.host.nil? or @config.login_url.nil?
            raise ArgumentError.new(":host and :login_url MUST be provided")
          end
        end

      end
    end
  end
end
