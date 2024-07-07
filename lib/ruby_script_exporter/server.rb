require 'sinatra'
require 'logger'

module RubyScriptExporter
  class Server < Sinatra::Base

    def self.service_directory=(service_directory)
      @service_directory = service_directory
    end

    def self.reload_on_request=(reload_on_request)
      @reload_on_request = reload_on_request
    end

    def self.services
      return @services if @services && !@reload_on_request

      @services = RubyScriptExporter::ScriptLoader.load_directory(@service_directory)
    end

    def self.run
      measurements = Executor.new(services, report_execution_time: true, report_counts: true).run
      Formatter.new(measurements).format
    end

    set :default_content_type, 'text'
    set :logging, Logger::DEBUG

    get '/metrics' do
      self.class.run
    end
  end
end

