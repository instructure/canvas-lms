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

class QuizGroup < ActiveRecord::Base
  attr_accessible :name, :pick_count, :question_points, :assessment_question_bank
  attr_readonly :quiz_id
  belongs_to :quiz
  belongs_to :assessment_question_bank
  has_many :quiz_questions, :dependent => :destroy
  before_save :infer_position
  validates_presence_of :quiz_id
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  
  def infer_position
    if !self.position && self.quiz
      self.position = self.quiz.root_entries_max_position + 1
    end
  end
  protected :infer_position
  
  def actual_pick_count
    if self.assessment_question_bank
      # don't do a valid question check because we don't want to instantiate all the bank's questions
      count = self.assessment_question_bank.assessment_question_count
    else
      count = self.quiz_questions.select{|q| q.unsupported != true}.length rescue self.quiz_questions.length
    end
    
    [self.pick_count.to_i, count].min
  end
  
  def clone_for(quiz, dup=nil, options={})
    dup ||= QuizGroup.new
    self.attributes.delete_if{|k,v| [:id, :quiz_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.quiz_id = quiz.id
    dup
  end

  # QuizGroup.data is used when creating and editing a quiz, but 
  # once the quiz is "saved" then the "rendered" version of the
  # quiz is stored in Quiz.quiz_data.  Hence, the teacher can
  # be futzing with questions and groups and not affect
  # the quiz, as students see it.
  def data
    {
      "id" => self.id,
      "name" => self.name,
      "pick_count" => self.pick_count,
      "question_points" => self.question_points,
      "questions" => self.assessment_question_bank_id ? [] : self.quiz_questions.map{|q| q.data},
      "assessment_question_bank_id" => self.assessment_question_bank_id
    }.with_indifferent_access
  end
  
  def self.import_from_migration(hash, context, quiz, question_data)
    hash = hash.with_indifferent_access
    item ||= QuizGroup.find_by_quiz_id_and_migration_id(quiz.id, hash[:migration_id].nil? ? nil : hash[:migration_id].to_s)
    item ||= quiz.quiz_groups.new
    item.migration_id = hash[:migration_id]
    item.question_points = hash[:question_points]
    item.pick_count = hash[:pick_count]
    if hash[:question_bank_migration_id]
      if bank = context.assessment_question_banks.find_by_migration_id(hash[:question_bank_migration_id])
        item.assessment_question_bank_id = bank.id
      end
    end
    item.save!
    hash[:questions].each do |question|
      if aq = question_data[question[:migration_id]]
        QuizQuestion.import_from_migration(aq, context, quiz, item)
      else
        #TODO: no assessment question was imported for this question...
      end
    end
    
    item
  end
end
