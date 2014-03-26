group :cassandra do
  gem 'cassandra-cql', '1.2.1', :github => 'kreynolds/cassandra-cql', :ref => 'd100be075b04153cf4116da7512892a1e8c0a7e4' #dependency of canvas_cassandra
  gem 'simple_uuid', '0.4.0'
  gem 'thrift', '0.8.0'
  gem 'thrift_client', '0.8.4'
  gem "canvas_cassandra", path: "gems/canvas_cassandra"
end

