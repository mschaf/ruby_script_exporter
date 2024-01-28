module RubyScriptExporter
  class Measurement

    attr_reader :measurement
    attr_reader :value

    def initialize(measurement, value, timestamp:, probe:, **labels)
      @measurement = measurement
      @value = value
      @probe = probe
      @labels = labels
      @timestamp = timestamp
    end

    def to_s
      "<Measurement #{@measurement} #{@value} #{@labels.inspect}>"
    end

    def combined_labels
      @probe.combined_labels.merge(@labels)
    end

    def format_as_open_metric
      line = @measurement.to_s

      if combined_labels.any?
        line << '{'
        line << combined_labels.map do |key, value|
          "#{key}=\"#{value}\""
        end.join(',')
        line << '}'
      end

      line << ' '
      line << @value.to_s

      if @probe.caches_result?
        line << ' '
        line << @timestamp.to_s
      end

      line
    end

  end
end