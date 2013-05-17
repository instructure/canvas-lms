class SubmissionPointsPossibleFixData < ActiveRecord::Migration
  def self.up
    case connection.adapter_name
      when 'MySQL', 'Mysql2'
        execute <<-SQL
          UPDATE quiz_submissions, quizzes
          SET quiz_points_possible = points_possible
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS SIGNED) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
      when 'PostgreSQL'
        execute <<-SQL
          UPDATE quiz_submissions
          SET quiz_points_possible = points_possible
          FROM quizzes
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS INTEGER) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
      # no fix needed for sqlite
    end
  end

  def self.down
  end
end
