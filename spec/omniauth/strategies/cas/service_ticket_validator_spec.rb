describe OmniAuth::Strategies::CAS::ServiceTicketValidator do
  let(:strategy_stub) do
    stub('strategy stub',
      service_validate_url: 'https://example.org/serviceValidate'
    )
  end

  let(:provider_options) do
    stub('provider options',
      disable_ssl_verification?: false,
      ca_path: '/etc/ssl/certsZOMG'
    )
  end

  let(:validator) do
    OmniAuth::Strategies::CAS::ServiceTicketValidator.new( strategy_stub, provider_options, '/foo', nil )
  end

  describe '#user_info' do
    subject do
      stub_request(:get, 'https://example.org/serviceValidate?').to_return(status: 200, body: '')
      validator.user_info
    end

    it 'should use the configured CA path' do
      provider_options.should_receive :ca_path

      subject
    end
  end
end