require 'awesome_print'
require 'omniauth/strategy'

module OmniAuth
  module Strategies
    class CAS
      include OmniAuth::Strategy

      option :name, :cas # TODO: Why do I need to specify this?

      option :host, nil
      option :port, nil # TODO: Default to 443 if ssl, else 80
      option :ssl,  true
      option :serviceValidateUri, '/serviceValidate'
      option :login_url,           '/login'
      option :logout_url,          '/logout'

      configure do |c|
        # ap "CONFIGURE!"
        # NOTE: This seems like a silly way to have to do this and differs from the inline docs/examples
        c.tap do |config|
          # TODO: Set port based on SSL, etc.
          config.foo = 'bar'
        end
      end

      # def callback_phase
      #   ap "CALLBACK PHASE"
      #   super
      # end

      # def request_call
      #   ap "REQUEST CALL"
      #   super
      # end

      # def setup_phase
      #   ap "SETUP PHASE"
      #   super
      # end

      def request_phase
        # ap "REQUEST PHASE"
        # ap @options
        [
          302,
          {
            'Location' => @options.login_url(callback_url),
            'Content-Type' => 'text/plain'
          },
          ["You are being redirected to CAS for sign-in."]
        ]
      end

      # uid do
      #   ap "UID"
      #   # request.params[options.uid_field.to_s]
      # end

      # info do
      #   ap "INFO"
      #   # options.fields.inject({}) do |hash, field|
      #   #   hash[field] = request.params[field.to_s]
      #   #   hash
      #   # end
      # end

      # extra do
      #   ap "EXTRA"
      # end

      # credentials do
      #   ap "CREDENTIALS"
      # end
    end
  end
end

OmniAuth.config.add_camelization 'cas', 'CAS'
