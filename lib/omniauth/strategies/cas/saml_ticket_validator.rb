require 'net/http'
require 'net/https'
require 'nokogiri'

module OmniAuth
  module Strategies
    class CAS
      class SamlTicketValidator

        VALIDATION_REQUEST_HEADERS = { 'Accept' => '*/*' }

        # Build a validator from a +configuration+, a
        # +return_to+ URL, and a +ticket+.
        #
        # @param [Hash] options the OmniAuth Strategy options
        # @param [String] return_to_url the URL of this CAS client service
        # @param [String] ticket the service ticket to validate
        def initialize(strategy, options, return_to_url, ticket)
          @options = options
          @uri = URI.parse(strategy.saml_validate_url(return_to_url))
          @time_uri = URI.parse(strategy.saml_time_url)
          @ticket = ticket
        end

        def call
          @response_body = get_service_response_body
          @success_body = find_authentication_success(@response_body)
          self
        end

        # Request validation of the ticket from the CAS server's
        # serviceValidate (CAS 2.0) function.
        #
        # Swallows all XML parsing errors (and returns +nil+ in those cases).
        #
        # @return [Hash, nil] a user information hash if the response is valid; +nil+ otherwise.
        #
        # @raise any connection errors encountered.
        def user_info
          parse_user_info(@success_body)
        end

      private

        # turns an `<cas:authenticationSuccess>` node into a Hash;
        # returns nil if given nil
        def parse_user_info(node)
          return nil if node.nil?

          h = {}
          if !node.blank?
            h["user"] = node.css("AttributeStatement").css("NameIdentifier")[0].children[0].to_s

            node.css("Attribute").each do |attr|
              h[attr.attributes["AttributeName"].value] = attr.children[0].children[0].to_s
            end
          end
          h
        end

        # finds an `<cas:authenticationSuccess>` node in
        # a `<cas:serviceResponse>` body if present; returns nil
        # if the passed body is nil or if there is no such node.
        #
        # Depending on the CAS implementation, the success value may be
        # samlp:Success or saml1p:Success, so we use a regexp to cover
        # the different cases.
        def find_authentication_success(body)
          return nil if body.nil? || body == ''
          begin
            doc = Nokogiri::XML(body)
            if @options.saml == true && doc.remove_namespaces!.xpath('//StatusCode').first.attributes['Value'].value =~ /saml[1]?[p]?:Success/
              doc.css('AttributeStatement')
            else
              nil
            end
          rescue Nokogiri::XML::XPath::SyntaxError
            nil
          end
        end

        # retrieves the `<cas:serviceResponse>` XML from the CAS server
        def get_service_response_body
          http = Net::HTTP.new(@uri.host, @uri.port)
          http.use_ssl = @uri.port == 443 || @uri.instance_of?(URI::HTTPS)
          http.ssl_version = @options.ssl_version.to_sym if @options.ssl_version
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @options.disable_ssl_verification?

          request_id = Time.now.to_i.to_s
          request_time = get_cas_server_time

          if request_time
            request_time = (Time.parse(request_time) + 10).utc.iso8601(3)
          else
            request_time = (Time.now + 10).utc.iso8601(3)
          end

          soap = "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"><SOAP-ENV:Header/><SOAP-ENV:Body>"
          soap += "<samlp:Request xmlns:samlp=\"urn:oasis:names:tc:SAML:1.0:protocol\" MajorVersion=\"1\" MinorVersion=\"1\" RequestID=\"#{request_id}\" IssueInstant=\"#{request_time}\">"
          soap += "<samlp:AssertionArtifact>#{@ticket}</samlp:AssertionArtifact>"
          soap += "</samlp:Request></SOAP-ENV:Body></SOAP-ENV:Envelope>"
          headers = {'Content-Type' => 'text/xml'}

          response, _data = http.post "#{@uri.path}?#{@uri.query}", soap, headers
          response.body
        end

        # This method exists only to get the servers time by making a light request and getting the response header date
        def get_cas_server_time
          http = Net::HTTP.new(@time_uri.host, @time_uri.port)
          http.use_ssl = @time_uri.port == 443 || @time_uri.instance_of?(URI::HTTPS)
          http.ssl_version = @options.ssl_version.to_sym if @options.ssl_version
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @options.disable_ssl_verification?

          begin
            raw_res = http.start do |conn|
              conn.get("#{@time_uri.path}?#{@time_uri.query}")
            end
          rescue Errno::ECONNREFUSED => _e
            return false
          end

          if raw_res.kind_of?(Net::HTTPSuccess) || raw_res.kind_of?(Net::HTTPRedirection)
            raw_res.header['date']
          else
            false
          end
        end

      end
    end
  end
end
