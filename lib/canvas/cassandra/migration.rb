module Canvas
  module Cassandra
    module Migration
      module ClassMethods
        def cassandra
          @cassandra ||= Canvas::Cassandra::DatabaseBuilder.from_config(cassandra_cluster)
        end

        def runnable?
          raise "cassandra_cluster is required to be defined" unless respond_to?(:cassandra_cluster) && cassandra_cluster.present?
          Switchman::Shard.current == Switchman::Shard.birth && Canvas::Cassandra::DatabaseBuilder.configured?(cassandra_cluster)
        end
      end

      def self.included(migration)
        migration.tag :cassandra
        migration.singleton_class.include(ClassMethods)
      end
    end
  end
end
