require 'http'

module RubyScriptExporter
  module Observers
    module Http
      Type.register_type(:http_status, :gauge, "HTTP response status: 0:good, 1:refused, 2:timeout, 3:name_not_resolved, 4:connection_failed, 5:certificate_error, 6:response_code_invalid, 7:response_body_invalid", global: true)
      Type.register_type(:http_response_time, :gauge, "HTTP response time", global: true)

      def observe_http(url, method: :get, expected_response_code: 200, expected_body: nil, timeout: 0.9)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response = HTTP.timeout(timeout).public_send(method, url)
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        observe :http_response_time, end_time - start_time

        if expected_response_code && expected_response_code != response.code
          observe :http_status, 6
          return
        end

        if expected_body && !response.body.to_s.match?(expected_body)
          observe :http_status, 7
          return
        end

        observe :http_status, 0
      rescue HTTP::ConnectionError => e
        case e.message
        when /Name or service not known/
          observe :http_status, 3 # Name not resolved
        when /Connection refused/
          observe :http_status, 1 # Connection refused
        else
          observe :http_status, 4 # Unknown connection error
        end
      rescue HTTP::ConnectTimeoutError, HTTP::TimeoutError => e
        observe :http_status, 2 # Connection timeout
      rescue OpenSSL::SSL::SSLError
        observe :http_status, 5 # Certificate invalid
      end

    end
  end
end