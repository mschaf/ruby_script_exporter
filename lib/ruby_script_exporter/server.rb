require 'sinatra'

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

    set :default_content_type, 'text'

    get '/metrics' do
      measurements = Executor.new(self.class.services).run
      Formatter.new(measurements).format
    end
  end
end

