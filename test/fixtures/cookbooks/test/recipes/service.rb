hab_sup 'default' do
  hab_channel 'stable'
  license 'accept'
  gateway_auth_token 'secret'
end

ruby_block 'wait-for-sup-default-startup' do
  block do
    raise unless system('hab sup status')
  end
  retries 30
  retry_delay 1
end

hab_package 'core/jq-static' do
  binlink true
end

# Test 1: Load Servoce (memcached)
hab_service 'core/memcached' do
  gateway_auth_token 'secret'
end

# Test 2: Load, then Unload Service (nginx)
hab_service 'core/nginx' do
  gateway_auth_token 'secret'
end

# Wait for load before attempting unload
ruby_block 'wait-for-nginx-load' do
  block do
    raise 'nginx not loaded' unless system 'hab svc status core/nginx'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/nginx]', :immediately
end
ruby_block 'wait-for-nginx-up' do
  block do
    raise 'nginx not loaded' unless `hab svc status core/nginx`.match(/standalone\s+up\s+up/)
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'ruby_block[wait-for-nginx-load]', :immediately
end

hab_service 'core/nginx unload' do
  service_name 'core/nginx'
  gateway_auth_token 'secret'
  action :unload
end

# Test 3: Load, then stop service (redis)
hab_service 'core/redis' do
  strategy :rolling
  topology :standalone
  update_condition 'latest'
  channel :stable
  gateway_auth_token 'secret'
end

# We need this sleep to let redis start and for the hab supervisor to
# recognize this and write the state file out otherwise our functional
# tests fail.
ruby_block 'wait-for-redis-load' do
  block do
    sleep 10
    raise 'redis not loaded' unless system 'hab svc status core/redis'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/redis]', :immediately
end
ruby_block 'wait-for-redis-started' do
  block do
    sleep 10
    raise 'redis not started' unless `hab svc status core/redis`.match(/standalone\s+up\s+up/)
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'ruby_block[wait-for-redis-load]', :immediately
end

hab_service 'core/redis stop' do
  gateway_auth_token 'secret'
  service_name 'core/redis'
  action :stop
end

ruby_block 'wait-for-redis-stopped' do
  block do
    sleep 10
    raise 'redis not stopped' unless `hab svc status core/redis`.match(/standalone\s+down\s+down/)
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/redis stop]', :immediately
end

hab_service 'core/redis start' do
  strategy :rolling
  topology :standalone
  service_name 'core/redis'
  update_condition 'latest'
  channel :stable
  gateway_auth_token 'secret'
  action :start
end

# Test 4: Full Identifier Test (grafana/6.4.3)
hab_service 'core/grafana full identifier' do
  service_name 'core/grafana/6.4.3/20191105024430'
  gateway_auth_token 'secret'
end

ruby_block 'wait-for-grafana-startup' do
  block do
    raise 'grafana not loaded' unless system 'hab svc status core/grafana'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/grafana full identifier]', :immediately
end

hab_service 'core/grafana full identifier idempotence' do
  service_name 'core/grafana/6.4.3/20191105024430'
  gateway_auth_token 'secret'
end

# Test 5: Change version (core/vault)
hab_service 'core/vault' do
  gateway_auth_token 'secret'
end

ruby_block 'wait-for-vault-load' do
  block do
    raise 'vault not loaded' unless system 'hab svc status core/vault'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/vault]', :immediately
end

hab_service 'core/vault version change' do
  service_name 'core/vault/1.1.5'
  gateway_auth_token 'secret'
end

# Test 6: Property Changes
hab_service 'core/grafana property change from defaults' do
  action :load
  service_name 'core/grafana/6.4.3/20191105024430'
  service_group 'test-1'
  bldr_url 'https://bldr-test-1.habitat.sh'
  strategy 'rolling'
  update_condition 'latest'
  shutdown_timeout 9
  health_check_interval 31
  gateway_auth_token 'secret'
end

hab_service 'core/grafana property change from custom values' do
  action :load
  service_name 'core/grafana/6.4.3/20191105024430'
  service_group 'test'
  bldr_url 'https://bldr-test.habitat.sh'
  channel 'bldr-1321420393699319808'
  topology :standalone
  strategy 'at-once'
  update_condition 'latest'
  binding_mode :relaxed
  shutdown_timeout 10
  health_check_interval 32
  gateway_auth_token 'secret'
end

# Test 7: Single Bind
hab_service 'core/prometheus' do
  gateway_auth_token 'secret'
end

ruby_block 'wait-for-prometheus-startup' do
  block do
    raise 'prometheus not loaded' unless system 'hab svc status core/prometheus'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/prometheus]', :immediately
end

hab_service 'core/grafana binding' do
  action :load
  service_name 'core/grafana/6.4.3/20191105024430'
  service_group 'test'
  bldr_url 'https://bldr-test.habitat.sh'
  channel 'bldr-1321420393699319808'
  topology :standalone
  strategy 'at-once'
  update_condition 'latest'
  bind 'prom:prometheus.default'
  binding_mode :relaxed
  shutdown_timeout 10
  health_check_interval 32
  gateway_auth_token 'secret'
end

# Test 8: Test Service Name Matching & Multiple Binds (sensu-backend & sensu + rabbitmq)
hab_service 'core/rabbitmq' do
  gateway_auth_token 'secret'
end

hab_service 'core/sensu-backend' do
  gateway_auth_token 'secret'
end

hab_service 'core/sensu' do
  bind [
    'rabbitmq:rabbitmq.default',
    'redis:redis.default',
  ]
  gateway_auth_token 'secret'
end

# Test 9: Restart the package
hab_service 'core/consul' do
  gateway_auth_token 'secret'
end

ruby_block 'wait-for-consul-load' do
  block do
    raise 'consul not loaded' unless system 'hab svc status core/consul'
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/consul]', :immediately
end
ruby_block 'wait-for-consul-startup' do
  block do
    raise 'consul not started' unless `hab svc status core/consul`.match(/standalone\s+up\s+up/)
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'ruby_block[wait-for-consul-load]', :immediately
end

ruby_block 'wait-for-consul-up-for-30s' do
  block do
    uptime = `hab svc status core/consul`.match(/standalone\s+up\s+up\s+([0-9]+)/)
    raise 'consul not started for 30s' unless uptime.size == 2 && Integer(uptime[1]) > 30
  end
  retries 30
  retry_delay 2
  action :nothing
  subscribes :run, 'ruby_block[wait-for-consul-startup]', :immediately
end

hab_service 'core/consul restart' do
  service_name 'core/consul'
  gateway_auth_token 'secret'
  action :restart
end

ruby_block 'wait-for-consul-restart' do
  block do
    uptime = `hab svc status core/consul`.match(/standalone\s+up\s+up\s+([0-9]+)/)
    raise 'consul not restarted' unless !uptime.nil? && uptime.size == 2 && Integer(uptime[1]) < 30
  end
  retries 60
  retry_delay 1
  action :nothing
  subscribes :run, 'hab_service[core/consul restart]', :immediately
end

# Test 10: Reload the package
ruby_block 'wait-for-consul-up-for-30s' do
  block do
    uptime = `hab svc status core/consul`.match(/standalone\s+up\s+up\s+([0-9]+)/)
    raise 'consul not started for 30s' unless uptime.size == 2 && Integer(uptime[1]) > 30
  end
  retries 30
  retry_delay 1
  action :nothing
  subscribes :run, 'ruby_block[wait-for-consul-startup]', :immediately
end

hab_service 'core/consul reload' do
  service_name 'core/consul'
  gateway_auth_token 'secret'
  action :reload
end

ruby_block 'wait-for-consul-restart' do
  block do
    uptime = `hab svc status core/consul`.match(/standalone\s+up\s+up\s+([0-9]+)/)
    raise 'consul not restarted' unless !uptime.nil? && uptime.size == 2 && Integer(uptime[1]) < 30
  end
  retries 5
  retry_delay 10
  action :nothing
  subscribes :run, 'hab_service[core/consul restart]', :immediately
end
