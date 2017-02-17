class SubmissionPointsPossibleFixData < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    case connection.adapter_name
      when 'PostgreSQL'
        update <<-SQL
          UPDATE #{Quizzes::QuizSubmission.quoted_table_name}
          SET quiz_points_possible = points_possible
          FROM #{Quizzes::Quiz.quoted_table_name}
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS INTEGER) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
    end
  end

  def self.down
  end
end
