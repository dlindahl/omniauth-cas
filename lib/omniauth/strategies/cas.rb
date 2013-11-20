require 'omniauth/strategy'
require 'addressable/uri'

module OmniAuth
  module Strategies
    class CAS
      include OmniAuth::Strategy

      # Custom Exceptions
      class MissingCASTicket < StandardError; end
      class InvalidCASTicket < StandardError; end

      autoload :Configuration, 'omniauth/strategies/cas/configuration'
      autoload :ServiceTicketValidator, 'omniauth/strategies/cas/service_ticket_validator'
      autoload :LogoutRequest, 'omniauth/strategies/cas/logout_request'

      attr_accessor :raw_info
      alias_method :user_info, :raw_info

      option :name, :cas # Required property by OmniAuth::Strategy

      option :host, nil
      option :port, nil
      option :path, nil
      option :ssl,  true
      option :service_validate_url, '/serviceValidate'
      option :login_url,            '/login'
      option :logout_url,           '/logout'
      option :uid_field,            'user'

      # As required by https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
      AuthHashSchemaKeys = %w{name email first_name last_name location image phone}
      info do
        prune!({
          :name       => raw_info['name'],
          :email      => raw_info['email'],
          :first_name => raw_info['first_name'],
          :last_name  => raw_info['last_name'],
          :location   => raw_info['location'],
          :image      => raw_info['image'],
          :phone      => raw_info['phone']
        })
      end

      extra do
        prune! raw_info.delete_if{ |k,v| AuthHashSchemaKeys.include?(k) }
      end

      uid do
        raw_info[ @options[:uid_field].to_s ]
      end

      credentials do
        prune!({
          :ticket => @ticket
        })
      end


      def callback_phase
        if on_sso_path?
          single_sign_out_phase
        else
          @ticket = request.params['ticket']
          return fail!(:no_ticket, MissingCASTicket.new('No CAS Ticket')) unless @ticket

          self.raw_info = ServiceTicketValidator.new(self, @options, callback_url, @ticket).user_info

          return fail!(:invalid_ticket, InvalidCASTicket.new('Invalid CAS Ticket')) if raw_info.empty?

          super
        end
      end

      def request_phase
        service_url = append_params( callback_url, return_url )

        [
          302,
          {
            'Location' => login_url( service_url ),
            'Content-Type' => 'text/plain'
          },
          ["You are being redirected to CAS for sign-in."]
        ]
      end

      def on_sso_path?
        request.post? && request.params.has_key?( 'logoutRequest' )
      end

      def single_sign_out_phase
        logout_request_service.new(self, request).call @options
      end

      # Build a CAS host with protocol and port
      #
      #
      def cas_url
        extract_url if @options['url']

        validate_cas_setup

        @cas_url ||= begin
          uri = Addressable::URI.new
          uri.host   = @options.host
          uri.scheme = @options.ssl ? 'https' : 'http'
          uri.port   = @options.port
          uri.path   = @options.path

          uri.to_s
        end
      end

      def extract_url
        url = Addressable::URI.parse( @options.delete('url') )

        @options.merge!(
            'host' => url.host,
            'port' => url.port,
            'path' => url.path,
            'ssl'  => url.scheme == 'https'
        )
      end

      def validate_cas_setup
        if @options.host.nil? || @options.login_url.nil?
          raise ArgumentError.new(":host and :login_url MUST be provided")
        end
      end

      # Build a service-validation URL from +service+ and +ticket+.
      # If +service+ has a ticket param, first remove it. URL-encode
      # +service+ and add it and the +ticket+ as paraemters to the
      # CAS serviceValidate URL.
      #
      # @param [String] service the service (a.k.a. return-to) URL
      # @param [String] ticket the ticket to validate
      #
      # @return [String] a URL like `http://cas.mycompany.com/serviceValidate?service=...&ticket=...`
      def service_validate_url(service_url, ticket)
        service_url = Addressable::URI.parse( service_url )
        service_url.query_values = service_url.query_values.tap { |qs| qs.delete('ticket') }

        cas_url + append_params(@options.service_validate_url, { :service => service_url.to_s, :ticket => ticket })
      end

      # Build a CAS login URL from +service+.
      #
      # @param [String] service the service (a.k.a. return-to) URL
      #
      # @return [String] a URL like `http://cas.mycompany.com/login?service=...`
      def login_url(service)
        cas_url + append_params( @options.login_url, { :service => service })
      end

      # Adds URL-escaped +parameters+ to +base+.
      #
      # @param [String] base the base URL
      # @param [String] params the parameters to append to the URL
      #
      # @return [String] the new joined URL.
      def append_params(base, params)
        params = params.each { |k,v| v = Rack::Utils.escape(v) }

        Addressable::URI.parse(base).tap do |base_uri|
          base_uri.query_values = (base_uri.query_values || {}).merge( params )
        end.to_s
      end

    private

      # Deletes Hash pairs with `nil` values.
      # From https://github.com/mkdynamic/omniauth-facebook/blob/972ed5e3456bcaed7df1f55efd7c05c216c8f48e/lib/omniauth/strategies/facebook.rb#L122-127
      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def return_url
        # If the request already has a `url` parameter, then it will already be appended to the callback URL.
        if request.params and request.params['url']
          {}
        else
          { :url => request.referer }
        end
      end

      def logout_request_service
        LogoutRequest
      end

    end
  end
end

OmniAuth.config.add_camelization 'cas', 'CAS'
