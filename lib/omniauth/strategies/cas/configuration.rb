module OmniAuth
  module Strategies
    class CAS
      class Configuration

        def initialize( options )
          @options = options

          validate_cas_setup
        end

        def validate_cas_setup
          if @options.host.nil? or @options.login_url.nil?
            raise ArgumentError.new(":host and :login_url MUST be provided")
          end
        end

      end
    end
  end
end
