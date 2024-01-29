type :some_metric, :counter, 'Some counter metric'

service 'some service' do
  probe 'some probe' do
    run do
      observe :some_metric, 123
    end
  end
end