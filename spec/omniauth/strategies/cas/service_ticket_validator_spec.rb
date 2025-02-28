# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::CAS::ServiceTicketValidator do
  let(:strategy) do
    instance_double(OmniAuth::Strategies::CAS, service_validate_url: 'https://example.org/serviceValidate')
  end
  let(:provider_options) do
    OmniAuth::Strategy::Options.new(
      disable_ssl_verification: false,
      merge_multivalued_attributes: false,
      ca_path: '/etc/ssl/certsZOMG'
    )
  end
  let(:validator) do
    described_class.new(strategy, provider_options, '/foo', nil)
  end

  describe '#call' do
    subject(:call) { validator.call }

    before do
      stub_request(:get, 'https://example.org/serviceValidate?')
        .to_return(status: 200, body: '')
    end

    it 'returns itself' do
      expect(call).to eq validator
    end

    it 'uses the configured CA path' do
      allow(provider_options).to receive(:ca_path)

      call

      expect(provider_options).to have_received :ca_path
    end
  end

  describe '#user_info' do
    subject(:user_info) { validator.user_info }

    let(:ok_fixture) do
      File.expand_path(File.join(File.dirname(__FILE__), '../../../fixtures/cas_success.xml'))
    end
    let(:service_response) { File.read(ok_fixture) }

    before do
      stub_request(:get, 'https://example.org/serviceValidate?')
        .to_return(status: 200, body: service_response)
      validator.call
    end

    context 'with default settings' do
      it 'parses user info from the response' do
        expect(user_info).to include 'user' => 'psegel'
        expect(user_info).to include 'roles' => 'financier'
      end
    end

    context 'when merging multivalued attributes' do
      let(:provider_options) do
        OmniAuth::Strategy::Options.new(merge_multivalued_attributes: true)
      end

      it 'parses multivalued user info from the response' do
        expect(user_info).to include 'user' => 'psegel'
        expect(user_info).to include 'roles' => %w[senator lobbyist financier]
      end
    end
  end
end
