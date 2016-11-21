class FixDeprecatedPolymorphicNames < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    reflections = [Quizzes::Quiz, Quizzes::QuizSubmission].map do |klass|
      klass.reflections.values.select { |r| r.macro == :has_many && r.options[:as] }
    end
    reflections.flatten!
    reflections.group_by(&:klass).each do |(klass, klass_reflections)|
      klass.find_ids_in_ranges(batch_size: 10000) do |min_id, max_id|
        klass_reflections.each do |reflection|
          klass.where(id: min_id..max_id,
                      reflection.type => reflection.active_record.name.sub("Quizzes::", "")).
                update_all(reflection.type => reflection.active_record.name)
        end
      end
    end
  end
end
