describe OmniAuth::Strategies::CAS::Configuration do
  subject { described_class.new }

  let(:options) { Hashie::Mash.new params }

  let(:params) do
    {
      'host' => 'example.org',
      'login_url' => '/'
    }
  end

  describe '#initialize' do
    let(:params) do
      {
        'url'       => 'http://example.org:8080',
        'login_url' => '/'
      }
    end

    it 'should initialize the configuration' do
      described_class.any_instance.should_receive(:extract_url)
      described_class.any_instance.should_receive(:validate_cas_setup)

      described_class.new options
    end

    context 'with a URL property' do
      subject { described_class.new( options ).instance_variable_get('@options') }

      it 'should parse the URL' do
        subject.host.should eq 'example.org'
        subject.port.should eq 8080
        subject.ssl.should  be_false
      end
    end

    context 'without a URL property' do
      let(:params) do
        {
          'host'      => 'example.org',
          'login_url' => '/'
        }
      end

      subject { described_class.new( options ) }

      it 'should not parse the url' do
        described_class.any_instance
          .should_receive(:extract_url)
          .never

        described_class.new options
      end
    end
  end
end
