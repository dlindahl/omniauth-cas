# frozen_string_literal: true

require 'spec_helper'

describe OmniAuth::Strategies::CAS::LogoutRequest do
  subject { described_class.new(strategy, request).call(options) }

  let(:strategy) { double('strategy') }
  let(:env) do
    { 'rack.input' => StringIO.new('', 'r') }
  end
  let(:request) { double('request', params: params, env: env) }
  let(:params) { { 'url' => url, 'logoutRequest' => logoutRequest } }
  let(:url) { 'http://example.org/signed_in' }
  let(:logoutRequest) do
    %(
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now}">
        <saml:NameID>@NOT_USED@</saml:NameID>
        <samlp:SessionIndex>ST-123456-123abc456def</samlp:SessionIndex>
      </samlp:LogoutRequest>
    )
  end

  describe 'SAML attributes' do
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
      subject
    end

    it 'are parsed and injected into the Rack Request parameters' do
      expect(@rack_input).to eq 'name_id=%40NOT_USED%40&session_index=ST-123456-123abc456def'
    end

    context 'that raise when parsed' do
      let(:env) { { 'rack.input' => nil } }

      before do
        allow(strategy).to receive(:fail!)
        subject
        expect(strategy).to have_received(:fail!)
      end

      it 'responds with an error' do
        expect(strategy).to have_received(:fail!)
      end
    end
  end

  describe 'with a configured callback' do
    let(:options) do
      { on_single_sign_out: callback }
    end

    let(:response_body) { subject[2].respond_to?(:body) ? subject[2].body : subject[2] }

    context 'that returns TRUE' do
      let(:callback) { proc { true } }

      it 'responds with OK' do
        expect(subject[0]).to eq 200
        expect(response_body).to eq ['OK']
      end
    end

    context 'that returns Nil' do
      let(:callback) { proc {} }

      it 'responds with OK' do
        expect(subject[0]).to eq 200
        expect(response_body).to eq ['OK']
      end
    end

    context 'that returns a tuple' do
      let(:callback) { proc { [400, {}, 'Bad Request'] } }

      it 'responds with OK' do
        expect(subject[0]).to eq 400
        expect(response_body).to eq ['Bad Request']
      end
    end

    context 'that raises an error' do
      let(:exception) { RuntimeError.new('error') }
      let(:callback) { proc { raise exception } }

      before do
        allow(strategy).to receive(:fail!)
        subject
      end

      it 'responds with an error' do
        expect(strategy).to have_received(:fail!)
          .with(:logout_request, exception)
      end
    end
  end
end
