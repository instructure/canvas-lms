#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module DataFixup::ReinsertAssessmentQuestionFileVerifiers
  def self.links_to_change(data)
    links = Set.new
    data.scan(/\/assessment_questions\/\d+\/files\/\d+[^\'\"\>]+/) do |link|
      links << link unless link.include?("verifier=")
    end
    updates = {}
    if links.any?
      att_id_map = Hash[links.map{|l| [l, l.match(/\/assessment_questions\/\d+\/files\/(\d+)/)[1].to_i]}]
      uuid_map = Hash[Attachment.where(:id => att_id_map.values, :context_type => "AssessmentQuestion").pluck(:id, :uuid)]
      new_data = data
      links.each do |link|
        uuid = uuid_map[att_id_map[link]]
        next unless uuid # just in case somehow the attachment disappeared
        uri = URI.parse(link)
        uri.query = ((uri.query || "").split("&") + ["verifier=#{uuid}"]).join("&")
        updates[link] = uri.to_s
      end
    end
    updates
  end

  def self.run
    date = DateTime.parse("2018-08-24")
    quiz_updates = {}
    qq_updates = {}

    Shackles.activate(:slave) do
      Quizzes::Quiz.find_ids_in_ranges do |min_id, max_id|
        Quizzes::Quiz.where(:id => min_id..max_id).
          where("updated_at > ? AND quiz_data LIKE ?", date, "%assessment_questions%").pluck(Arel.sql("id, quiz_data as qd")).each do |id, data|
          updates = links_to_change(data)
          quiz_updates[id] = updates if updates.any?
        end
      end

      Quizzes::QuizQuestion.find_ids_in_ranges do |min_id, max_id|
        Quizzes::QuizQuestion.where(:id => min_id..max_id).
          where("updated_at > ? AND question_data LIKE ? AND (assessment_question_id IS NOT NULL OR migration_id IS NOT NULL)",
            date, "%assessment_questions%").pluck(Arel.sql("id, question_data as qd")).each do |id, data|
          updates = links_to_change(data)
          qq_updates[id] = updates if updates.any?
        end
      end
    end

    quiz_updates.each do |id, updates|
      sql = "quiz_data = replace(quiz_data, ?, ?), updated_at = ?"
      (updates.count - 1).times do
        sql.sub!("replace(quiz_data", "replace(replace(quiz_data, ?, ?)")
      end
      update_sql = User.send(:sanitize_sql, [sql] + updates.to_a.flatten + [Time.now.utc])
      Quizzes::Quiz.where(:id => id).update_all(update_sql)
    end

    qq_updates.each do |id, updates|
      sql = "question_data = replace(question_data, ?, ?), updated_at = ?"
      (updates.count - 1).times do
        sql.sub!("replace(question_data", "replace(replace(question_data, ?, ?)")
      end
      update_sql = User.send(:sanitize_sql, [sql] + updates.to_a.flatten + [Time.now.utc])
      Quizzes::QuizQuestion.where(:id => id).update_all(update_sql)
    end
  end
end
