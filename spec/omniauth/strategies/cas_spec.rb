require File.expand_path( 'spec/spec_helper' )

describe OmniAuth::Strategies::CAS, :type => :strategy do
  include Rack::Test::Methods

  class MyCasProvider < OmniAuth::Strategies::CAS; end # TODO: Not really needed. just an alias but it requires the :name option which might confuse users...
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use MyCasProvider, :name => :cas, :host => 'cas.example.org', :uid_key => :employeeid
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  # TODO: Verify that these are even useful tests
  shared_examples_for "a CAS redirect response" do
    let(:redirect_params) { "service=" + Rack::Utils.escape("http://example.org/auth/cas/callback?url=#{Rack::Utils.escape(return_url)}") }
    before do
      get url, nil, request_env
    end
    subject { last_response }
    it { should be_redirect }
    it "should redirect to the CAS server" do
      subject.headers['Location'].should == "https://cas.example.org/login?" + redirect_params
    end
  end

  describe 'GET /auth/cas' do
    let(:return_url) { 'http://myapp.com/admin/foo' }

    context "with a referer" do
      let(:url) { '/auth/cas' }
      let(:request_env) { { 'HTTP_REFERER' => return_url } }
      it_behaves_like "a CAS redirect response"
    end
    context "with an explicit return URL" do
      let(:url) { "/auth/cas?url=#{return_url}" }
      let(:request_env) { {} }

      it_behaves_like "a CAS redirect response"
    end
  end

  describe 'GET /auth/cas/callback without a ticket' do
    before do
      get '/auth/cas/callback'
    end

    subject { last_response }

    it { should be_redirect }
    it "should have a failure message" do
      subject.headers['Location'].should == "/auth/failure?message=no_ticket&strategy=cas"
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
      subject.headers['Location'].should == "/auth/failure?message=invalid_ticket&strategy=cas"
    end
  end

  describe 'GET /auth/cas/callback with a valid ticket' do
    let(:return_url) { "http://127.0.0.10/?some=parameter" }
    before do
      stub_request(:get, /^https:\/\/cas.example.org(:443)?\/serviceValidate\?([^&]+&)?ticket=593af/).
         with { |request| @request_uri = request.uri.to_s }.
         to_return( :body => File.read('spec/fixtures/cas_success.xml') )

      get "/auth/cas/callback?ticket=593af&url=#{return_url}"
    end

    it 'should strip the ticket parameter from the callback URL' do
      @request_uri.scan('ticket=').length.should == 1
    end

    it "should properly encode the service URL" do
      WebMock.should have_requested(:get, "https://cas.example.org/serviceValidate")
        .with(:query => {
          :ticket => "593af",
          :service => "http://example.org/auth/cas/callback?url=" + Rack::Utils.escape("http://127.0.0.10/?some=parameter")
        })
    end

    context "request.env['omniauth.auth']" do
      subject { last_request.env['omniauth.auth'] }
      it { should be_kind_of Hash }
      its(:provider) { should == :cas }
      its(:uid) { should == '54'}

      context "the info hash" do
        subject { last_request.env['omniauth.auth']['info'] }
        it { should have(6).items }
        its('name') { should == 'Peter Segel' }
        its('first_name') { should == 'Peter' }
        its('last_name') { should == 'Segel' }
        its('email') { should == 'psegel@intridea.com' }
        its('location') { should == 'Washington, D.C.' }
        its('image') { should == '/images/user.jpg' }
        its('phone') { should == '555-555-5555' }
      end
      context "the extra hash" do
        subject { last_request.env['omniauth.auth']['extra'] }
        it { should have(3).items }
        its('user') { should == 'psegel' }
        its('employeeid') { should == '54' }
        its('hire_date') { should == '2004-07-13' }
      end
      context "the credentials hash" do
        subject { last_request.env['omniauth.auth']['credentials'] }
        it { should have(1).items }
        its('ticket') { should == '593af' }
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