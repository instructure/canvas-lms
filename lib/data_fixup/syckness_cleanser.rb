module DataFixup
  module SycknessCleanser
    def self.columns_hash
      result = ActiveRecord::Base.all_models.map do |model|
        next unless model.superclass == ActiveRecord::Base
        next unless model.connection.table_exists?(model.table_name)
        next if model.name == 'RemoveQuizDataIds::QuizQuestionDataMigrationARShim'

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

    def self.run(model, columns)
      update_sqls = {}
      quoted = {}

      columns.each do |column|
        quoted[column] = model.connection.quote_column_name(column)
        update_sqls[column] = "#{quoted[column]} = left(#{quoted[column]}, -#{Syckness::TAG.length})"
      end
      model.find_ids_in_ranges do |min_id, max_id|
        columns.each do |column|
          model.where(model.primary_key => min_id..max_id).where("#{quoted[column]} LIKE ?", "%#{Syckness::TAG}").update_all(update_sqls[column])
        end
        delay = Setting.get("syckness_sleeping_ms", nil)
        if delay
          sleep(delay.to_i.fdiv(1000)) # just in case the cleansing is a little too strong
        end
      end
    end
  end
end