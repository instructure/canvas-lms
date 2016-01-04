class FixMoreDeprecatedPolymorphicNames < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def up
    tables = {
      attachments: {
        context_type: 'QuizStatistics'
      },
      cloned_items: {
        original_item_type: 'Quiz'
      },
      delayed_messages: {
        context_type: 'QuizSubmission'
      },
      delayed_notifications: {
        asset_type: 'QuizSubmission'
      },
      learning_outcome_question_results: {
        associated_asset_type: 'Quiz'
      },
      learning_outcome_result: {
        association_type: 'Quiz',
        associated_asset_type: 'Quiz',
        artifact_type: 'QuizSubmission'
      },
      messages: {
        context_type: ['QuizSubmission', 'QuizRegradeRun'],
        asset_context_type: ['QuizSubmission', 'QuizRegradeRun']
      },
      progress: {
        context_type: 'QuizStatistics'
      }
    }

    tables.each do |(table, columns)|
      klass = table.to_s.classify.constantize
      klass.find_ids_in_ranges(batch_size: 10000) do |min_id, max_id|
        columns.each do |(column, types)|
          Array(types).each do |type|
            klass.where(id: min_id..max_id, column => type).
              update_all(column => "Quizzes::#{type}")
          end
        end
      end
    end
  end
end
