group :cassandra do
  gem 'cassandra-cql', '1.2.2', github: 'kreynolds/cassandra-cql', ref: 'beed72e249d02cebc850a4b92b468c8b64b12257' #dependency of canvas_cassandra
    gem 'simple_uuid', '0.4.0', require: false
    gem 'thrift', '0.8.0', require: false
    gem 'thrift_client', '0.8.4', require: false
  gem "canvas_cassandra", path: "gems/canvas_cassandra"
end

