module RubyScriptExporter
  module Util

    def self.counterize(string, count)
      string = string.prepend('s') if count != 1

      "#{count} #{string}"
    end

    def self.parse_options
      options = {
        service_dir: 'example_services/',
        reload_on_request: false,
        port: 9100,
        host: '0.0.0.0',
        raise_errors: false,
      }

      OptionParser.new do |opts|
        opts.banner = "Usage: ruby_script_exporter [options]"

        opts.on("-s SERVICE_DIR", "--script-directory SERVICE_DIR", "Specify where to look for service definitions") do |service_dir|
          options[:service_dir] = service_dir
        end

        opts.on("-r", "--reload-on-request", "Reload service definitions for every request, useful for developing probes") do
          options[:reload_on_request] = true
        end

        opts.on("--raise-errors", "Stop and print errors instead of raising the error count") do
          options[:raise_errors] = true
        end

      end.parse!

      RubyScriptExporter::Server.service_directory = options[:service_dir]
      RubyScriptExporter::Server.reload_on_request = options[:reload_on_request]
      RubyScriptExporter::Probe.raise_errors = options[:raise_errors]

      options
    end

  end
end
