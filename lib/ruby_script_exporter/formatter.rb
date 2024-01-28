module RubyScriptExporter
  class Formatter

    def initialize(measurements)
      @measurements = measurements
    end

    def format
      output = []

      @measurements.group_by(&:measurement).map do |type, measurements|
        type = Type.from_name(type)
        output << type.format_for_open_metrics

        measurements.each do |measurement|
          output << measurement.format_as_open_metric
        end
      end

      output.join("\n")
    end
  end
end