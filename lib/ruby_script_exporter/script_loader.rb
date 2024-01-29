module RubyScriptExporter
  class ScriptLoader

    attr_reader :services

    def initialize
      @services = []
    end

    def service(name, &block)
      service_builder = RubyScriptExporter::Service::Builder.new(name)
      service_builder.instance_eval(&block)
      @services << service_builder.service
    end

    def type(name, type, help = nil)
      Type.register_type(name, type, help)
    end

    def self.load_string(string)
      loader = ScriptLoader.new
      Type.clear_types
      loader.instance_eval string
      loader.services
    end

    def self.load_file(file)
      load_string File.open(file).read
    end

    def self.load_directory(directory)
      unless directory.start_with?('/')
        directory = File.join(Dir.pwd, directory)
      end
      directory = File.join(directory, '/*.rb')

      service_files = Dir[directory]

      puts "Loading service definitions ..."
      services = service_files.map { load_file(_1) }.flatten
      probe_count = services.map(&:probes).flatten.count
      puts "Loaded #{Util.counterize('service', services.count)} with a total of #{Util.counterize('probe', probe_count)}"

      services
    end
  end
end

