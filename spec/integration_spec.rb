describe 'gathering metrics' do

  it 'loads services from a directory containing files' do
    services = RubyScriptExporter::ScriptLoader.load_directory('spec/fixtures/basic_integration')
    executor = RubyScriptExporter::Executor.new(services)
    metrics = executor.run
    formatter = RubyScriptExporter::Formatter.new(metrics)
    output = formatter.format

    expect(output).to eq <<~OUTPUT.strip
      # HELP some_metric Some counter metric
      # TYPE some_metric counter
      some_metric{service="some service",probe="some probe"} 123
    OUTPUT
  end

  def execute_script(script, **executor_options)
    services = RubyScriptExporter::ScriptLoader.load_string(script)
    executor = RubyScriptExporter::Executor.new(services, **executor_options)
    metrics = executor.run
    formatter = RubyScriptExporter::Formatter.new(metrics)
    formatter.format
  end

  it 'respects all kind of labels' do
    output = execute_script(<<~SCRIPT)
      service 'some service' do
        label :some_service_label, 'label on the service level'
  
        probe 'some probe' do
          label :some_probe_label, 'label on the probe level'

          run do
            observe :some_metric, 123
          end
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # TYPE some_metric gauge
      some_metric{service="some service",some_service_label="label on the service level",probe="some probe",some_probe_label="label on the probe level"} 123
    OUTPUT
  end

  it 'can overwrite labels from service an probe definitions' do
    output = execute_script(<<~SCRIPT)
      service 'some service' do
        label :service, nil
  
        probe 'some probe' do
          label :probe, nil

          run do
            observe :some_metric, 123
          end
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # TYPE some_metric gauge
      some_metric 123
    OUTPUT
  end

  def probe_services(services, **executor_options)
    executor = RubyScriptExporter::Executor.new(services, **executor_options)
    metrics = executor.run
    formatter = RubyScriptExporter::Formatter.new(metrics)
    formatter.format
  end

  it 'can cache some probes' do
    $counter_1 = 0
    $counter_2 = 0

    services = RubyScriptExporter::ScriptLoader.load_string(<<~SCRIPT)
      service 'some service' do

        probe 'some probe' do
          run do
            $counter_1 += 1
            observe :counter_1, $counter_1
          end
        end

        probe 'some cached probe' do
          cache_for 30

          run do
            $counter_2 += 1
            observe :counter_2, $counter_2
          end
        end
      end
    SCRIPT

    Timecop.freeze(Time.parse('01.01.2024 12:00:00'))

    expect(probe_services(services)).to eq <<~OUTPUT.strip
      # TYPE counter_1 gauge
      counter_1{service="some service",probe="some probe"} 1
      # TYPE counter_2 gauge
      counter_2{service="some service",probe="some cached probe"} 1 1704106800000
    OUTPUT

    Timecop.freeze(Time.parse('01.01.2024 12:00:29'))

    expect(probe_services(services)).to eq <<~OUTPUT.strip
      # TYPE counter_1 gauge
      counter_1{service="some service",probe="some probe"} 2
      # TYPE counter_2 gauge
      counter_2{service="some service",probe="some cached probe"} 1 1704106800000
    OUTPUT

    Timecop.freeze(Time.parse('01.01.2024 12:00:31'))

    expect(probe_services(services)).to eq <<~OUTPUT.strip
      # TYPE counter_1 gauge
      counter_1{service="some service",probe="some probe"} 3
      # TYPE counter_2 gauge
      counter_2{service="some service",probe="some cached probe"} 2 1704106831000
    OUTPUT
  end

  it 'respects all kind of labels' do
    output = execute_script(<<~SCRIPT)
      service 'some service' do
        label :some_service_label, 'label on the service level'
  
        probe 'some probe' do
          label :some_probe_label, 'label on the probe level'

          run do
            observe :some_metric, 123
          end
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # TYPE some_metric gauge
      some_metric{service="some service",some_service_label="label on the service level",probe="some probe",some_probe_label="label on the probe level"} 123
    OUTPUT
  end

  it 'can report about successful probes' do
    output = execute_script(<<~SCRIPT, report_counts: true)
      service 'some service' do 
        probe 'some probe' do
          run {}
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # HELP cached_probe_count Count of probes which returned a cached result
      # TYPE cached_probe_count gauge
      cached_probe_count 0
      # HELP error_probe_count Count probes witch threw an error while executing
      # TYPE error_probe_count gauge
      error_probe_count 0
      # HELP successful_probe_count Count of probes which ran successfully
      # TYPE successful_probe_count gauge
      successful_probe_count 1
      # HELP timeout_probe_count Count of probes which timed out
      # TYPE timeout_probe_count gauge
      timeout_probe_count 0
      # HELP total_probe_count Total probe count
      # TYPE total_probe_count gauge
      total_probe_count 1
    OUTPUT
  end

  it 'can report about failing probes' do
    output = execute_script(<<~SCRIPT, report_counts: true)
      service 'some service' do 
        probe 'some probe' do
          run do
            raise 'something'
          end
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # HELP cached_probe_count Count of probes which returned a cached result
      # TYPE cached_probe_count gauge
      cached_probe_count 0
      # HELP error_probe_count Count probes witch threw an error while executing
      # TYPE error_probe_count gauge
      error_probe_count 1
      # HELP successful_probe_count Count of probes which ran successfully
      # TYPE successful_probe_count gauge
      successful_probe_count 0
      # HELP timeout_probe_count Count of probes which timed out
      # TYPE timeout_probe_count gauge
      timeout_probe_count 0
      # HELP total_probe_count Total probe count
      # TYPE total_probe_count gauge
      total_probe_count 1
    OUTPUT
  end

  it 'can report about probes which time out' do
    output = execute_script(<<~SCRIPT, report_counts: true)
      service 'some service' do 
        probe 'some probe' do
          timeout 0.1

          run do
            sleep 0.2
          end
        end
      end
    SCRIPT

    expect(output).to eq <<~OUTPUT.strip
      # HELP cached_probe_count Count of probes which returned a cached result
      # TYPE cached_probe_count gauge
      cached_probe_count 0
      # HELP error_probe_count Count probes witch threw an error while executing
      # TYPE error_probe_count gauge
      error_probe_count 0
      # HELP successful_probe_count Count of probes which ran successfully
      # TYPE successful_probe_count gauge
      successful_probe_count 0
      # HELP timeout_probe_count Count of probes which timed out
      # TYPE timeout_probe_count gauge
      timeout_probe_count 1
      # HELP total_probe_count Total probe count
      # TYPE total_probe_count gauge
      total_probe_count 1
    OUTPUT
  end

  it 'can report about probes which time out' do
    output = execute_script(<<~SCRIPT, report_execution_time: true)
      service 'some service' do 
        probe 'some probe' do
          run do
            sleep 0.1
          end
        end

        probe 'some other probe' do
          run do
            sleep 0.2
          end
        end
      end
    SCRIPT

    probe_execution_time = output.match(/probe_execution_time{service="some service",probe="some probe"} (0\.\d+)/)[1]
    other_probe_execution_time = output.match(/probe_execution_time{service="some service",probe="some other probe"} (0\.\d+)/)[1]
    total_probe_execution_time = output.match(/total_execution_time (0\.\d+)/)[1]

    expect(probe_execution_time.to_f.round(2)).to eq 0.1
    expect(other_probe_execution_time.to_f.round(2)).to eq 0.2
    expect(total_probe_execution_time.to_f.round(2)).to eq 0.3
  end

end