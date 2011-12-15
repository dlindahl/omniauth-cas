require File.expand_path( 'spec/spec_helper' )

describe OmniAuth::Strategies::CAS, :type => :strategy do
  include Rack::Test::Methods

  class MyCasProvider < OmniAuth::Strategies::CAS; end # TODO: Not really needed. just an alias but it requires the :name option which might confuse users...
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use MyCasProvider, :name => :cas, :host => 'cas.example.org'
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  # def session
  #   last_request.env['rack.session']
  # end

  describe 'GET /auth/cas' do
    before do
      get '/auth/cas'
    end

    subject { last_response }

    it { should be_redirect }
    it "should redirect to the CAS server" do
      subject.headers['Location'].should == "https://cas.example.org/login?service=" + CGI.escape("http://example.org/auth/cas/callback")
    end
  end

  describe 'GET /auth/cas/callback without a ticket' do
    before do
      get '/auth/cas/callback'
    end

    subject { last_response }

    it { should be_redirect }
    it "should have a failure message" do
      subject.headers['Location'].should =~ /message=no_ticket/
    end
  end

  describe 'GET /auth/cas/callback with an invalid ticket' do
    before do
      stub_request(:get, /^https:\/\/cas.example.org(:443)?\/serviceValidate\?([^&]+&)?ticket=9391d/).
         to_return( :body => File.read('spec/fixtures/cas_failure.xml') )
      get '/auth/cas/callback?ticket=9391d'
    end

    subject { last_response }

    it { should be_redirect }
    it 'should have a failure message' do
      subject.headers['Location'].should =~ /message=invalid_ticket/
    end
  end

  describe 'GET /auth/cas/callback with a valid ticket' do
    before do
      stub_request(:get, /^https:\/\/cas.example.org(:443)?\/serviceValidate\?([^&]+&)?ticket=593af/).
         with { |request| @request_uri = request.uri.to_s }.
         to_return( :body => File.read('spec/fixtures/cas_success.xml') )
      get '/auth/cas/callback?ticket=593af'
    end

    it 'should strip the ticket parameter from the callback URL' do
      @request_uri.scan('ticket=').length.should == 1
    end

    context "request.env['omniauth.auth']" do
      subject { last_request.env['omniauth.auth'] }
      it { should be_kind_of Hash }
      its(:provider) { should == :cas }
      its(:uid) { should == 'psegel'}

      context "['extra']" do
        subject { last_request.env['omniauth.auth']['extra'] }
        it { should be_kind_of Hash }
        its('first-name') { should == 'Peter' }
        its('last-name') { should == 'Segel' }
        its('hire-date') { should == '2004-07-13' }
      end
    end

    it 'should call through to the master app' do
      last_response.body.should == 'true'
    end
  end

  # unless RUBY_VERSION =~ /^1\.8\.\d$/
  #   describe 'GET /auth/cas/callback with a valid ticket and gzipped response from the server on ruby >1.8' do
  #     before do
  #       zipped = StringIO.new
  #       Zlib::GzipWriter.wrap zipped do |io|
  #         io.write File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'cas_success.xml'))
  #       end
  #       stub_request(:get, /^https:\/\/cas.example.org(:443)?\/serviceValidate\?([^&]+&)?ticket=593af/).
  #          with { |request| @request_uri = request.uri.to_s }.
  #          to_return(:body => zipped.string, :headers => { 'content-encoding' => 'gzip' })
  #       get '/auth/cas/callback?ticket=593af'
  #     end
  # 
  #     it 'should call through to the master app when response is gzipped' do
  #         last_response.body.should == 'true'
  #     end
  #   end
  # end
end