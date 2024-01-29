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

  def execute_script(script)
    services = RubyScriptExporter::ScriptLoader.load_string(script)
    executor = RubyScriptExporter::Executor.new(services)
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

  def probe_services(services)
    executor = RubyScriptExporter::Executor.new(services)
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
end