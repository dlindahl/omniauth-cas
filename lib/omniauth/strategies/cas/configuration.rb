module OmniAuth
  module Strategies
    class CAS
      class Configuration

        def initialize( options )
          @options = options

          extract_url if @options['url']

          validate_cas_setup
        end

        def extract_url
          url = Addressable::URI.parse( @options.delete('url') )

          @options.merge!(
            'host' => url.host,
            'port' => url.port,
            'ssl'  => url.scheme == 'https'
          )
        end

        def validate_cas_setup
          if @options.host.nil? || @options.login_url.nil?
            raise ArgumentError.new(":host and :login_url MUST be provided")
          end
        end

      end
    end
  end
end
