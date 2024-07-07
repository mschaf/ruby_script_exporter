# frozen_string_literal: true

module RubyScriptExporter
  class Probe

    class ScriptError < StandardError; end
    class ScriptTimeout < StandardError; end

    attr_reader :name
    attr_reader :labels
    attr_accessor :cache_for
    attr_accessor :timeout
    attr_writer :runner_proc
    attr_reader :service

    def self.raise_errors=(raise_errors)
      @raise_errors = raise_errors
    end

    def self.raise_errors
      @raise_errors
    end

    def initialize(name, service)
      @name = name
      @service = service
      @labels = {}
      @last_measurements = nil
      @last_run_at = nil
      @timeout = 1
    end

    def combined_labels
      @service.combined_labels.merge({
        probe: @name,
      }).merge(@labels).compact
    end

    def caches_result?
      !!cache_for
    end

    def run
      if caches_result? && @last_measurements && @last_run_at > (Time.now.to_f - @cache_for)
        return [@last_measurements, :cached]
      end

      raise ArgumentError, 'No runner given' unless @runner_proc

      runner = Runner.new(self)

      start_time = nil
      end_time = nil
      begin
        Timeout::timeout(@timeout) do
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          runner.instance_eval(&@runner_proc)
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      rescue Timeout::Error
        raise ScriptTimeout
      rescue StandardError => e
        if self.class.raise_errors
          raise e
        end

        raise ScriptError, e.inspect
      end

      execution_time = end_time - start_time

      @last_run_at = Time.now.to_f
      @last_measurements = runner.measurements
      [@last_measurements, execution_time]
    end
  end

  class Probe::Builder
    attr_accessor :probe

    def initialize(name, service)
      @probe = Probe.new(name, service)
    end

    def cache_for(time)
       @probe.cache_for = time
    end

    def timeout(timeout)
      @probe.timeout = timeout
    end

    def label(key, value)
      @probe.labels[key] = value
    end

    def run(&block)
      @probe.runner_proc = block
    end
  end

end
