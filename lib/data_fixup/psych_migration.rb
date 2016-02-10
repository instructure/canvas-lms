require "safe_yaml/psych_resolver"
require "safe_yaml/safe_to_ruby_visitor"

module DataFixup::PsychMigration
  class << self
    def run
      raise "Rails 4.0 specific" unless CANVAS_RAILS4_0

      columns_hash.each do |model, columns|
        next if model.shard_category == :unsharded && Shard.current != Shard.default

        if ranges = id_ranges(model)
          ranges.each do |start_at, end_at|
            queue_migration(model, columns, start_at, end_at)
          end
        else
          queue_migration(model, columns)
        end
      end
    end

    def queue_migration(model, columns, start_at=nil, end_at=nil)
      args = [model, columns, start_at, end_at]
      if run_immediately?
        self.migrate_yaml(nil, *args)
      else
        progress = Progress.create!(:context => Account.site_admin, :tag => "psych_migration")
        progress.set_results({:model_name => model.name, :start_at => start_at, :end_at => end_at})
        progress.process_job(self, :migrate_yaml, {:n_strand => ["psych_migration", Shard.current.database_server.id],
          :priority => Delayed::MAX_PRIORITY, :max_attempts => 1}, *args)
      end
    end

    def run_immediately?
      !Rails.env.production?
    end

    def migrate_yaml(progress, model, columns, start_at, end_at)
      total_count = 0
      unparsable_count = 0
      changed_count = 0

      use_shard_id = (model <= Delayed::Backend::ActiveRecord::Job) && model.column_names.include?('shard_id')

      model.find_ids_in_ranges(:batch_size => 50, :start_at => start_at, :end_at => end_at) do |min_id, max_id|
        # rename the columns on the pluck so that Rails doesn't silently deserialize them for us
        to_pluck = columns.map { |c| "#{c} AS #{c}1" }
        to_pluck << :shard_id if use_shard_id

        model.transaction do
          rows = model.shard(Shard.current).where(model.primary_key => min_id..max_id).lock(:no_key_update).pluck(model.primary_key, *to_pluck)
          rows.each do |row|
            changes = {}

            shard = (use_shard_id && Shard.lookup(row.pop)) || Shard.current
            shard.activate do
              columns.each_with_index do |column, i|
                value = row[i + 1]
                next if value.nil? || value.end_with?(Syckness::TAG)

                obj_from_syck = begin
                  YAML.unsafe_load(value)
                rescue
                  unparsable_count += 1
                  nil
                end

                if obj_from_syck
                  obj_from_psych = Psych.load(value) rescue nil
                  if obj_from_syck != obj_from_psych
                    Utf8Cleaner.recursively_strip_invalid_utf8!(obj_from_syck, true)
                    changes[column] = YAML.dump(obj_from_syck)
                  end
                end
              end
            end

            next if changes.empty?

            model.where(model.primary_key => row.first).update_all(changes)
            changed_count += 1
          end

          total_count += rows.count
        end
      end
      if progress
        progress.set_results(progress.results.merge(:successful => true, :total_count => total_count,
          :changed_count => changed_count, :unparsable_count => unparsable_count))
      end
    end

    def columns_hash
      result = ActiveRecord::Base.all_models.map do |model|
        next unless model.superclass == ActiveRecord::Base

        attributes = model.serialized_attributes.select do |attr, coder|
          coder.is_a?(ActiveRecord::Coders::YAMLColumn)
        end
        next if attributes.empty?
        [model, attributes.keys]
      end.compact.to_h
      result[Version] = ['yaml']
      result[Delayed::Backend::ActiveRecord::Job] = ['handler']
      result[Delayed::Backend::ActiveRecord::Job::Failed] = ['handler']
      result
    end

    def range_size
      1_000_000
    end

    def id_ranges(model)
      # try to partition off ranges of ids in the table with at most 1,000,000 ids per partition
      return unless model.primary_key == "id"

      ranges = []
      scope = model.shard(Shard.current).where("id < ?", Shard::IDS_PER_SHARD)
      start_id = scope.minimum(:id)
      return unless start_id

      current_min = start_id

      while current_min
        current_max = current_min + range_size - 1

        next_min = scope.where("id > ?", current_max).minimum(:id)
        if next_min
          ranges << [current_min, current_max]
        elsif !next_min && ranges.any?
          ranges << [current_min, nil] # grab all the rest of the rows if we're at the end - including shadow objects
        end
        current_min = next_min
      end

      ranges if ranges.any?
    end
  end
end