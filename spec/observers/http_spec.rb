describe 'http observer' do

  def execute_script(script, **executor_options)
    services = RubyScriptExporter::ScriptLoader.load_string(script)
    executor = RubyScriptExporter::Executor.new(services, **executor_options)
    metrics = executor.run
    formatter = RubyScriptExporter::Formatter.new(metrics)
    formatter.format
  end

  subject do
    execute_script(<<~SCRIPT)
      service 'some service' do
        probe 'some probe' do
          run do
            observe_http("http://example.com/login",
              method: :post,
              expected_body: /Login/,
              expected_response_code: 201,
              timeout: 0.5,
            )
          end
        end
      end
    SCRIPT
  end

  context 'when everything is fine' do
    before do
      stub_request(:post, "http://example.com/login").
        to_return(body: "Login", status: 201)
    end

    it 'reports the http status 0' do
      expect(subject).to match /http_response_time{service="some service",probe="some probe"} 0.\d+/
      expect(subject).to include 'http_status{service="some service",probe="some probe"} 0'
    end
  end

  context 'the connection is refused' do
    before do
      stub_request(:post, "http://example.com/login").
        to_raise HTTP::ConnectionError.new('Connection refused')
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 1' }
  end

  context 'the connection times out' do
    before do
      stub_request(:post, "http://example.com/login").
        to_timeout
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 2' }
  end

  context 'dns fails to resolve' do
    before do
      stub_request(:post, "http://example.com/login").
        to_raise HTTP::ConnectionError.new('Name or service not known')
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 3' }
  end


  context 'unknown connection error' do
    before do
      stub_request(:post, "http://example.com/login").
        to_raise HTTP::ConnectionError
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 4' }
  end

  context 'ssl error' do
    before do
      stub_request(:post, "http://example.com/login").
        to_raise OpenSSL::SSL::SSLError
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 5' }
  end

  context 'wrong http status' do
    before do
      stub_request(:post, "http://example.com/login").
        to_return(body: "", status: 404)
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 6' }
  end

  context 'wrong http body' do
    before do
      stub_request(:post, "http://example.com/login").
        to_return(body: "Foo", status: 201)
    end

    it { is_expected.to include 'http_status{service="some service",probe="some probe"} 7' }
  end
end