# frozen_string_literal: true

module RubyScriptExporter
  class Probe

    attr_reader :name
    attr_reader :labels
    attr_accessor :cache_for
    attr_writer :runner_proc

    def initialize(name, service)
      @name = name
      @service = service
      @labels = {}
      @last_measurements = nil
      @last_run_at = nil
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
        return @last_measurements
      end

      raise ArgumentError, 'No runner given' unless @runner_proc

      runner = Runner.new(self)
      runner.instance_eval(&@runner_proc)
      @last_run_at = Time.now.to_f
      @last_measurements = runner.measurements
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

    def label(key, value)
      @probe.labels[key] = value
    end

    def run(&block)
      @probe.runner_proc = block
    end
  end

end
