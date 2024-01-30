# ruby_script_exporter

ruby_script_exporter is a small framework to expose metrics produced by ruby snippets to prometheus.

## Installation

`gem install ruby_script_exporter`

## Usage

```
Usage: ruby_script_exporter [options]
    -s SERVICE_DIR, --script-directory   Specify where to look for service definitions
    -r, --reload-on-request              Reload service definitions for every request, useful for developing probes
```

## Example Probe

`services/example_probe.rb`:  

```
type :some_metric, :gauge, 'Some random metric'

service 'some service' do
  probe 'some probe' do
    label :some_label, 'Foo'
    
    run do
       observe :some_metric, 123
    end
  end
end
```
 
Run the exporter with `ruby_script_exporter` and get `http://localhost:9100` for:  

```
# HELP cached_probe_count Count of probes which returned a cached result
# TYPE cached_probe_count gauge
cached_probe_count 0
# HELP error_probe_count Count probes witch threw an error while executing
# TYPE error_probe_count gauge
error_probe_count 0
# HELP probe_execution_time Execution time per probe
# TYPE probe_execution_time gauge
probe_execution_time{service="some service",probe="some probe",some_label="Foo"} 7.915019523352385e-06
# HELP some_metric Some random metric
# TYPE some_metric gauge
some_metric{service="some service",probe="some probe",some_label="Foo"} 123
# HELP successful_probe_count Count of probes which ran successfully
# TYPE successful_probe_count gauge
successful_probe_count 1
# HELP timeout_probe_count Count of probes which timed out
# TYPE timeout_probe_count gauge
timeout_probe_count 0
# HELP total_execution_time Total execution time
# TYPE total_execution_time gauge
total_execution_time 6.38000201433897e-05
# HELP total_probe_count Total probe count
# TYPE total_probe_count gauge
total_probe_count 1
```

Next to `some_metric` there are also a number of internal metrics exposed.
