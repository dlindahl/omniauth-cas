require 'spec_helper'

describe OmniAuth::Strategies::CAS::ServiceTicketValidator do
  let(:strategy) do
    double('strategy',
      service_validate_url: 'https://example.org/serviceValidate'
    )
  end
  let(:provider_options) do
    double('provider_options',
      disable_ssl_verification?: false
    )
  end
  let(:validator) do
    OmniAuth::Strategies::CAS::ServiceTicketValidator.new( strategy, provider_options, '/foo', nil )
  end

  describe '#call' do
    before do
      stub_request(:get, 'https://example.org/serviceValidate?')
        .to_return(status: 200, body: '')
    end

    subject { validator.call }

    it 'returns itself' do
      expect(subject).to eq validator
    end

    describe 'https certs' do
      let(:const) { OmniAuth::Strategies::CAS::ServiceTicketValidator::CUSTOM_SSL_CERTS_GLOB }

      after { subject }

      specify { expect(Dir).to receive(:[]).with(const).and_call_original }
    end
  end

  describe '#user_info' do
    let(:ok_fixture) do
      File.expand_path(File.join(File.dirname(__FILE__), '../../../fixtures/cas_success.xml'))
    end
    let(:service_response) { File.read(ok_fixture) }

    before do
      stub_request(:get, 'https://example.org/serviceValidate?')
        .to_return(status: 200, body:service_response)
      validator.call
    end

    subject { validator.user_info }

    it 'parses user info from the response' do
      expect(subject).to include 'user' => 'psegel'
    end
  end
end
