#
# Copyright (C) 2011 Instructure, Inc.
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
#

class Quizzes::QuizGroup < ActiveRecord::Base
  self.table_name = 'quiz_groups' unless CANVAS_RAILS2

  attr_accessible :name, :pick_count, :question_points, :assessment_question_bank_id
  attr_readonly :quiz_id

  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :assessment_question_bank
  has_many :quiz_questions, :class_name => 'Quizzes::QuizQuestion', :dependent => :destroy

  validates_presence_of :quiz_id
  validates_length_of :name, maximum: maximum_string_length, allow_nil: true
  validates_numericality_of :pick_count, :question_points, allow_nil: true

  before_save :infer_position
  before_destroy :update_quiz
  after_save :update_quiz

  def actual_pick_count
    count = if self.assessment_question_bank
              # don't do a valid question check because we don't want to instantiate all the bank's questions
              self.assessment_question_bank.assessment_question_count
            else
              self.quiz_questions.active.count
            end

    [self.pick_count.to_i, count].min
  end

  # QuizGroup.data is used when creating and editing a quiz, but
  # once the quiz is "saved" then the "rendered" version of the
  # quiz is stored in Quizzes::Quiz.quiz_data.  Hence, the teacher can
  # be futzing with questions and groups and not affect
  # the quiz, as students see it.
  def data
    {
      "id" => self.id,
      "name" => self.name,
      "pick_count" => self.pick_count,
      "question_points" => self.question_points,
      "questions" => self.assessment_question_bank_id ? [] : self.quiz_questions.active.map { |q| q.data },
      "assessment_question_bank_id" => self.assessment_question_bank_id
    }.with_indifferent_access
  end

  def self.update_all_positions!(groups)
    return unless groups.size > 0

    updates = groups.map do |group|
      "WHEN id=#{group.id.to_i} THEN #{group.position.to_i}"
    end
    set = "position=CASE #{updates.join(" ")} ELSE NULL END"
    where(:id => groups).update_all(set)
  end

  def self.import_from_migration(hash, context, quiz, question_data, position = nil, migration = nil)
    hash = hash.with_indifferent_access
    item ||= Quizzes::QuizGroup.find_by_quiz_id_and_migration_id(quiz.id, hash[:migration_id].nil? ? nil : hash[:migration_id].to_s)
    item ||= quiz.quiz_groups.new
    item.migration_id = hash[:migration_id]
    item.question_points = hash[:question_points]
    item.pick_count = hash[:pick_count]
    item.position = position
    item.name = hash[:title] || t('#quizzes.quiz_group.question_group', "Question Group")
    if hash[:question_bank_migration_id]
      if hash[:question_bank_is_external] && migration && migration.user && hash[:question_bank_context].present? && hash[:question_bank_migration_id].present?
        bank = nil
        bank_context = nil

        if hash[:question_bank_context] =~ /account_(\d*)/
          bank_context = Account.find_by_id($1)
        elsif hash[:question_bank_context] =~ /course_(\d*)/
          bank_context = Course.find_by_id($1)
        end

        if bank_context
          bank = bank_context.assessment_question_banks.find_by_id(hash[:question_bank_migration_id])
        end

        if bank
          if bank.grants_right?(migration.user, nil, :read)
            item.assessment_question_bank_id = bank.id
          else
            migration.add_warning(t('#quizzes.quiz_group.errors.no_permissions', "User didn't have permission to reference question bank in quiz group %{group_name}", :group_name => item.name))
          end
        else
          migration.add_warning(t('#quizzes.quiz_group.errors.no_bank', "Couldn't find the question bank for quiz group %{group_name}", :group_name => item.name))
        end
      else
        if bank = context.assessment_question_banks.find_by_migration_id(hash[:question_bank_migration_id])
          item.assessment_question_bank_id = bank.id
        end
      end
    end
    item.save!
    hash[:questions].each_with_index do |question, i|
      if qq = question_data[:qq_data][question[:migration_id]]
        qq[:position] = i + 1
        if qq[:assessment_question_migration_id]
          if aq = question_data[:aq_data][qq[:assessment_question_migration_id]]
            qq['assessment_question_id'] = aq['assessment_question_id']
            aq_hash = AssessmentQuestion.prep_for_import(qq, context)
            Quizzes::QuizQuestion.import_from_migration(aq_hash, context, quiz, item)
          else
            aq_hash = AssessmentQuestion.import_from_migration(qq, context)
            qq['assessment_question_id'] = aq_hash['assessment_question_id']
            Quizzes::QuizQuestion.import_from_migration(aq_hash, context, quiz, item)
          end
        end
      elsif aq = question_data[:aq_data][question[:migration_id]]
        aq[:points_possible] = question[:points_possible] if question[:points_possible]
        aq[:position] = i + 1
        Quizzes::QuizQuestion.import_from_migration(aq, context, quiz, item)
      end
    end

    item
  end

  private

  def update_quiz
    Quizzes::Quiz.mark_quiz_edited(self.quiz_id)
  end

  def infer_position
    if !self.position && self.quiz
      self.position = self.quiz.root_entries_max_position + 1
    end
  end
end
