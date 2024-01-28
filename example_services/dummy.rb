type :time, :counter, 'Seconds since 1970'

service 'dummy service' do
  label :service_label, '1234'

  probe 'dummy probe' do
    run do
      observe :time, Time.now
    end
  end

  probe 'cached dummy probe' do
    cache_for 30

    run do
      observe :time, Time.now
    end
  end
end