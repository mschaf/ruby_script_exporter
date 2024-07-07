module RubyScriptExporter
  class Runner

    include Observers::Http

    attr_reader :measurements

    def initialize(probe)
      @probe = probe
      @measurements = []
    end

    def observe(measurement, value, **labels)
      timestamp = Time.now.to_i * 1000
      @measurements << Measurement.new(measurement, value, timestamp:, probe: @probe, **labels)
    end
  end
end

