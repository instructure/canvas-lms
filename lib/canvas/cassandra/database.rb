# This is simply a backwards-compatibility shim, once plugins are all updated
# we can delete this file

module Canvas::Cassandra
  module Database
    class << self
      delegate :configured?, :from_config, :config_names, to: '::Canvas::Cassandra::DatabaseBuilder'
    end
  end
end
