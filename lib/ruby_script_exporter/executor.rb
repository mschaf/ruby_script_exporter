module RubyScriptExporter
  class Executor

    def initialize(services)
      @services = services
    end

    def probes
      @services.map(&:probes).flatten
    end

    def run
      probes.map(&:run).flatten
    end

  end
end