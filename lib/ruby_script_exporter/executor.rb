module RubyScriptExporter
  class Executor

    Type.register_type(:cached_probe_count, :gauge, 'Count of probes which returned a cached result', global: true)
    Type.register_type(:error_probe_count, :gauge, 'Count probes witch threw an error while executing', global: true)
    Type.register_type(:successful_probe_count, :gauge, 'Count of probes which ran successfully', global: true)
    Type.register_type(:timeout_probe_count, :gauge, 'Count of probes which timed out', global: true)
    Type.register_type(:total_probe_count, :gauge, 'Total probe count', global: true)
    Type.register_type(:probe_execution_time, :gauge, 'Execution time per probe', global: true)
    Type.register_type(:total_execution_time, :gauge, 'Total execution time', global: true)

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
        rescue Probe::ScriptError => e
          STDERR.puts "Error while executing #{probe.inspect}: #{e.inspect}"
          error_count += 1
          next
        rescue Probe::ScriptTimeout
          STDERR.puts "Timeout while executing #{probe.inspect}"
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