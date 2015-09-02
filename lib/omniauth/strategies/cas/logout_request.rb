module OmniAuth
  module Strategies
    class CAS
      class LogoutRequest
        def initialize(strategy, request)
          @strategy, @request = strategy, request
        end

        def call(options = {})
          @options = options

          begin
            result = single_sign_out_callback.call(*logout_request)
          rescue StandardError => err
            return @strategy.fail! :logout_request, err
          else
            result = [200,{},'OK'] if result == true || result.nil?
          ensure
            return unless result

            # TODO: Why does ActionPack::Response return [status,headers,body]
            # when Rack::Response#new wants [body,status,headers]? Additionally,
            # why does Rack::Response differ in argument order from the usual
            # Rack-like [status,headers,body] array?
            return Rack::Response.new(result[2],result[0],result[1]).finish
          end
        end

      private

        def logout_request
          @logout_request ||= begin
            saml = Nokogiri.parse(@request.params['logoutRequest'])
            ns = saml.collect_namespaces
            name_id = saml.xpath('//saml:NameID', ns).text
            sess_idx = saml.xpath('//samlp:SessionIndex', ns).text
            inject_params(name_id:name_id, session_index:sess_idx)
            @request
          end
        end

        def inject_params(new_params)
          new_params.each do |k,v|
            @request.update_param(k,v)
          end
        end

        def single_sign_out_callback
          @options[:on_single_sign_out]
        end
      end
    end
  end
end
