module RubyScriptExporter
  class Executor

    def initialize(services, report_execution_time: false, report_counts: false)
      @services = services
      @report_execution_time = report_execution_time
      @report_counts = report_counts
    end

    def probes
      @services.map(&:probes).flatten
    end

    def run
      total_count = 0
      successful_count = 0
      cached_count = 0
      error_count = 0
      timeout_count = 0
      measurements = []

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      probes.each do |probe|
        total_count += 1

        begin
          probe_measurements, execution_time = probe.run
        rescue Probe::ScriptError
          error_count += 1
          next
        rescue Probe::ScriptTimeout
          timeout_count += 1
          next
        end

        measurements.concat(probe_measurements)

        successful_count += 1
        if execution_time == :cached
          execution_time = 0
          cached_count += 1
        end

        if @report_execution_time
          measurements << Measurement.new(:probe_execution_time, execution_time,
            probe: probe,
          )
        end
      end

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      total_execution_time = end_time - start_time

      if @report_execution_time
        measurements << Measurement.new(:total_execution_time, total_execution_time)
      end

      if @report_counts
        measurements << Measurement.new(:total_probe_count, total_count)
        measurements << Measurement.new(:successful_probe_count, successful_count)
        measurements << Measurement.new(:cached_probe_count, cached_count)
        measurements << Measurement.new(:error_probe_count, error_count)
        measurements << Measurement.new(:timeout_probe_count, timeout_count)
      end

      measurements
    end

  end
end