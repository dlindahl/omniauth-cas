# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::CAS::LogoutRequest do
  subject(:call) { described_class.new(strategy, request).call(options) }

  let(:strategy) { instance_double(OmniAuth::Strategies::CAS) }
  let(:env) do
    { 'rack.input' => StringIO.new('', 'r') }
  end
  let(:request) { instance_double(Rack::Request, params: params, env: env) }
  let(:params) { { 'url' => url, 'logoutRequest' => logout_request_xml } }
  let(:url) { 'http://example.org/signed_in' }
  let(:logout_request_xml) do
    <<~XML
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now}">
        <saml:NameID>@NOT_USED@</saml:NameID>
        <samlp:SessionIndex>ST-123456-123abc456def</samlp:SessionIndex>
      </samlp:LogoutRequest>
    XML
  end

  context 'when parsing SAML attributes' do
    let(:callback) { proc {} }
    let(:options) do
      { on_single_sign_out: callback }
    end

    before do
      @rack_input = nil
      allow(callback).to receive(:call) do |req|
        @rack_input = req.env['rack.input'].read
        true
      end
      call
    end

    it 'injects them into the Rack Request parameters' do
      expect(@rack_input).to eq 'name_id=%40NOT_USED%40&session_index=ST-123456-123abc456def'
    end

    context 'when an error is raised' do
      let(:env) { { 'rack.input' => nil } }

      before do
        allow(strategy).to receive(:fail!)
        call
      end

      it 'responds with an error' do
        expect(strategy).to have_received(:fail!)
      end
    end
  end

  context 'with a configured callback' do
    let(:options) do
      { on_single_sign_out: callback }
    end

    let(:response_body) { call[2].respond_to?(:body) ? call[2].body : call[2] }

    context 'when callback returns `true`' do
      let(:callback) { proc { true } }

      it 'responds with OK' do
        expect(call[0]).to eq 200
        expect(response_body).to eq ['OK']
      end
    end

    context 'when callback returns `nil`' do
      let(:callback) { proc {} }

      it 'responds with OK' do
        expect(call[0]).to eq 200
        expect(response_body).to eq ['OK']
      end
    end

    context 'when callback returns a tuple' do
      let(:callback) { proc { [400, {}, 'Bad Request'] } }

      it 'responds with OK' do
        expect(call[0]).to eq 400
        expect(response_body).to eq ['Bad Request']
      end
    end

    context 'when callback raises an error' do
      let(:exception) { RuntimeError.new('error') }
      let(:callback) { proc { raise exception } }

      before do
        allow(strategy).to receive(:fail!)
        call
      end

      it 'responds with an error' do
        expect(strategy).to have_received(:fail!)
          .with(:logout_request, exception)
      end
    end
  end
end
