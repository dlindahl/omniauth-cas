# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::CAS, type: :strategy do
  include Rack::Test::Methods

  let(:my_cas_provider) { Class.new(described_class) }
  let(:app) do
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use MyCasProvider,
          name: :cas,
          host: 'cas.example.org',
          ssl: false,
          port: 8080,
          uid_field: :employeeid,
          fetch_raw_info: proc { |_v, _opts, _ticket, info, node|
            if info.empty?
              {}
            else
              {
                'roles' => node.xpath('//cas:roles').map(&:text)
              }
            end
          }
      run ->(env) { [404, { 'Content-Type' => 'text/plain' }, [env.key?('omniauth.auth').to_s]] }
    end.to_app
  end

  before do
    stub_const 'MyCasProvider', my_cas_provider
  end

  # TODO: Verify that these are even useful tests
  shared_examples_for 'a CAS redirect response' do
    subject { last_response }

    let(:redirect_params) { "service=#{Rack::Utils.escape("http://example.org/auth/cas/callback?url=#{Rack::Utils.escape(return_url)}")}" }

    before { post url, nil, request_env }

    it { is_expected.to be_redirect }

    it 'redirects to the CAS server' do
      expect(subject.headers).to include 'Location' => "http://cas.example.org:8080/login?#{redirect_params}"
    end
  end

  describe '#cas_url' do
    subject(:cas_url) { provider.cas_url }

    let(:params) { {} }
    let(:provider) { MyCasProvider.new(nil, params) }

    it 'raises an ArgumentError' do
      expect { cas_url }.to raise_error ArgumentError, /:host and :login_url MUST be provided/
    end

    context 'with an explicit :url option' do
      let(:url) { 'https://example.org:8080/my_cas' }
      let(:params) { super().merge url: url }

      before { cas_url }

      it { is_expected.to eq url }

      it 'parses the URL into it the appropriate strategy options' do
        expect(provider.options).to include ssl: true
        expect(provider.options).to include host: 'example.org'
        expect(provider.options).to include port: 8080
        expect(provider.options).to include path: '/my_cas'
      end
    end

    context 'with explicit URL component' do
      let(:params) { super().merge host: 'example.org', port: 1234, ssl: true, path: '/a/path' }

      before { cas_url }

      it { is_expected.to eq 'https://example.org:1234/a/path' }

      it 'parses the URL into it the appropriate strategy options' do
        expect(provider.options).to include ssl: true
        expect(provider.options).to include host: 'example.org'
        expect(provider.options).to include port: 1234
        expect(provider.options).to include path: '/a/path'
      end
    end
  end

  describe 'defaults' do
    subject { MyCasProvider.default_options.to_hash }

    it { is_expected.to include('ssl' => true) }
  end

  describe 'POST /auth/cas' do
    let(:return_url) { 'http://example.org/admin/foo' }

    context 'with a referer' do
      let(:url) { '/auth/cas' }

      let(:request_env) { { 'HTTP_REFERER' => return_url } }

      it_behaves_like 'a CAS redirect response'
    end

    context 'with an explicit return URL' do
      let(:url) { "/auth/cas?url=#{return_url}" }

      let(:request_env) { {} }

      it_behaves_like 'a CAS redirect response'
    end
  end

  describe 'POST /auth/cas/callback' do
    context 'without a ticket' do
      subject { last_response }

      before { get '/auth/cas/callback' }

      it { is_expected.to be_redirect }

      it 'redirects with a failure message' do
        expect(last_response.headers).to include 'Location' => '/auth/failure?message=no_ticket&strategy=cas'
      end
    end

    context 'with an invalid ticket' do
      subject { last_response }

      before do
        stub_request(:get, %r{^http://cas.example.org:8080?/serviceValidate\?([^&]+&)?ticket=9391d})
          .to_return(body: File.read('spec/fixtures/cas_failure.xml'))
        get '/auth/cas/callback?ticket=9391d'
      end

      it { is_expected.to be_redirect }

      it 'redirects with a failure message' do
        expect(last_response.headers).to include 'Location' => '/auth/failure?message=invalid_ticket&strategy=cas'
      end
    end

    context 'with a valid ticket' do
      shared_examples 'successful validation' do
        before do
          stub_request(:get, %r{^http://cas.example.org:8080?/serviceValidate\?([^&]+&)?ticket=593af})
            .with { |request| @request_uri = request.uri.to_s }
            .to_return(body: File.read("spec/fixtures/#{xml_file_name}"))

          get "/auth/cas/callback?ticket=593af&url=#{return_url}"
        end

        it 'strips the ticket parameter from the callback URL' do
          expect(@request_uri.scan('ticket=').size).to eq 1
        end

        it 'properly encodes the service URL' do
          expect(WebMock).to have_requested(:get, 'http://cas.example.org:8080/serviceValidate')
            .with(query: {
                    ticket: '593af',
                    service: "http://example.org/auth/cas/callback?url=#{Rack::Utils.escape('http://127.0.0.10/?some=parameter')}"
                  })
        end

        describe "request.env['omniauth.auth']" do
          subject { last_request.env['omniauth.auth'] }

          it { is_expected.to be_a Hash }

          it 'identifes the provider' do
            expect(subject.provider).to eq :cas
          end

          it 'returns the UID of the user' do
            expect(subject.uid).to eq '54'
          end

          describe "['info']" do
            subject { last_request.env['omniauth.auth']['info'] }

            it 'includes user info attributes' do
              expect(subject.name).to eq 'Peter Segel'
              expect(subject.first_name).to eq 'Peter'
              expect(subject.last_name).to eq 'Segel'
              expect(subject.nickname).to eq 'psegel'
              expect(subject.email).to eq 'psegel@intridea.com'
              expect(subject.location).to eq 'Washington, D.C.'
              expect(subject.image).to eq '/images/user.jpg'
              expect(subject.phone).to eq '555-555-5555'
            end
          end

          describe "['extra']" do
            subject { last_request.env['omniauth.auth']['extra'] }

            it 'includes additional user attributes' do
              expect(subject.user).to eq 'psegel'
              expect(subject.employeeid).to eq '54'
              expect(subject.hire_date).to eq '2004-07-13'
              expect(subject.roles).to eq %w[senator lobbyist financier]
            end

            context 'when skip_info? is specified' do
              let(:app) do
                Rack::Builder.new do
                  use OmniAuth::Test::PhonySession
                  use MyCasProvider,
                      name: :cas,
                      host: 'cas.example.org',
                      ssl: false,
                      port: 8080,
                      uid_field: :employeeid,
                      skip_info: true
                  run ->(env) { [404, { 'Content-Type' => 'text/plain' }, [env.key?('omniauth.auth').to_s]] }
                end.to_app
              end

              it 'does not include additional user attributes' do
                expect(subject).to be_empty
              end
            end
          end

          describe "['credentials']" do
            subject { last_request.env['omniauth.auth']['credentials'] }

            it 'has a ticket value' do
              expect(subject.ticket).to eq '593af'
            end
          end
        end

        it 'calls through to the master app' do
          expect(last_response.body).to eq 'true'
        end
      end

      let(:return_url) { 'http://127.0.0.10/?some=parameter' }

      context 'with JASIG flavored XML' do
        let(:xml_file_name) { 'cas_success_jasig.xml' }

        it_behaves_like 'successful validation'
      end

      context 'with classic XML' do
        let(:xml_file_name) { 'cas_success.xml' }

        it_behaves_like 'successful validation'
      end
    end

    describe 'with a Single Sign-Out logoutRequest' do
      subject(:sso_logout_request) do
        post 'auth/cas/callback', logoutRequest: logout_request_xml
      end

      let(:logout_request_xml) do
        <<~XML
          <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now}">
            <saml:NameID>@NOT_USED@</saml:NameID>
            <samlp:SessionIndex>ST-123456-123abc456def</samlp:SessionIndex>
          </samlp:LogoutRequest>
        XML
      end

      let(:logout_request) { instance_double(MyCasProvider::LogoutRequest, call: [200, {}, 'OK']) }

      before do
        allow(MyCasProvider::LogoutRequest)
          .to receive(:new)
          .and_return logout_request

        sso_logout_request
      end

      it 'initializes a LogoutRequest' do
        expect(logout_request).to have_received :call
      end
    end
  end
end
