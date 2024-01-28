# frozen_string_literal: true

module RubyScriptExporter
  class Service

    attr_reader :name
    attr_reader :probes
    attr_reader :labels

    def initialize(name)
      @name = name
      @probes = []
      @labels = {}
    end

    def combined_labels
      {
        service: @name,
      }.merge(@labels).compact
    end

  end

  class Service::Builder
    attr_reader :service

    def initialize(name)
      @service = Service.new(name)
    end

    def label(key, value)
      @service.labels[key] = value
    end

    def probe(name, &block)
      probe_builder = Probe::Builder.new(name, @service)
      probe_builder.instance_eval(&block)
      @service.probes << probe_builder.probe
    end
  end
end
