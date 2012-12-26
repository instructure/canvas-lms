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

require 'quiz_question_link_migrator'

class QuizQuestion < ActiveRecord::Base
  attr_accessible :quiz, :quiz_group, :assessment_question, :question_data, :assessment_question_version, :quiz_group, :quiz
  attr_readonly :quiz_id
  belongs_to :quiz
  belongs_to :assessment_question
  belongs_to :quiz_group
  before_save :infer_defaults
  before_save :create_assessment_question
  before_destroy :delete_assessment_question
  validates_presence_of :quiz_id
  serialize :question_data
  after_save :update_quiz
  
  def infer_defaults
    if !self.position && self.quiz
      if self.quiz_group
        self.position = (self.quiz_group.quiz_questions.map(&:position).compact.max || 0) + 1
      else
        self.position = self.quiz.root_entries_max_position + 1
      end
    end
  end
  protected :infer_defaults
  
  def update_quiz
    Quiz.update_all({:last_edited_at => Time.now.utc}, {:id => self.quiz_id})
  end
  
  def question_data=(data)
    if data.is_a?(String)
      data = ActiveSupport::JSON.decode(data) rescue nil
    elsif data.class == Hash
      data = data.with_indifferent_access
    end
    return if data == self.question_data
    data = AssessmentQuestion.parse_question(data, self.assessment_question)
    data[:name] = data[:question_name]
    write_attribute(:question_data, data)
  end
  
  def question_data
    if data = read_attribute(:question_data)
      if data.class == Hash
        data = write_attribute(:question_data, data.with_indifferent_access)
      end
    end
    
    data
  end
  
  def delete_assessment_question
    if self.assessment_question && self.assessment_question.editable_by?(self)
      self.assessment_question.destroy
    end
  end
  
  def create_assessment_question
    return if self.question_data && self.question_data[:question_type] == 'text_only_question'
    self.assessment_question ||= AssessmentQuestion.new
    if self.assessment_question.editable_by?(self)
      self.assessment_question.question_data = self.question_data
      self.assessment_question.initial_context = self.quiz.context if self.quiz && self.quiz.context
      self.assessment_question.save if self.assessment_question.new_record?
      self.assessment_question_id = self.assessment_question.id
      self.assessment_question_version = self.assessment_question.version_number rescue nil
    end
    true
  end
  
  def self.migrate_question_hash(hash, params)
    if params[:old_context] && params[:new_context]
      migrator = lambda { |value| Course.migrate_content_links(value, params[:old_context], params[:new_context]) }
    elsif params[:context] && params[:user]
      migrator = lambda { |value| Course.copy_authorized_content(value, params[:context], params[:user]) }
    else
      return hash
    end

    [:question_text, :correct_comments, :incorrect_comments, :neutral_comments, :text_after_answers].each do |key|
      hash[key] = migrator.call(hash[key]) if hash[key]
    end
    hash[:answers].each do |answer|
      [:html, :comments_html].each do |key|
        answer[key] = migrator.call(answer[key]) if answer[key].present?
      end
    end if hash[:answers]

    hash
  end
  
  def clone_for(quiz, dup=nil, options={})
    dup ||= QuizQuestion.new
    self.attributes.delete_if{|k,v| [:id, :quiz_id, :quiz_group_id, :question_data].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    data = self.question_data || HashWithIndifferentAccess.new
    data.delete(:id)
    if options[:old_context] && options[:new_context]
      data = QuizQuestion.migrate_question_hash(data, options)
    end
    dup.write_attribute(:question_data, data)
    dup.quiz_id = quiz.id
    dup
  end

  # QuizQuestion.data is used when creating and editing a quiz, but 
  # once the quiz is "saved" then the "rendered" version of the
  # quiz is stored in Quiz.quiz_data.  Hence, the teacher can
  # be futzing with questions and groups and not affect
  # the quiz, as students see it.
  def data
    res = (self.question_data || self.assessment_question.question_data) rescue {}
    res[:assessment_question_id] = self.assessment_question_id
    res[:question_name] = t('defaults.question_name', "Question") if res[:question_name].blank?
    res[:id] = self.id
    res.with_indifferent_access
  end

  def self.import_from_migration(hash, context, quiz=nil, quiz_group=nil)
    unless hash[:prepped_for_import]
      AssessmentQuestion.prep_for_import(hash, context)
    end

    question_data = self.connection.quote hash.to_yaml
    aq_id = hash['assessment_question_id'] ? hash['assessment_question_id'] : 'NULL'
    g_id = quiz_group ? quiz_group.id : 'NULL'
    q_id = quiz ? quiz.id : 'NULL'
    position = hash[:position].nil? ? 'NULL' : hash[:position].to_i
    if id = hash['quiz_question_id']
      query = "UPDATE quiz_questions"
      query += " SET quiz_group_id = #{g_id}, assessment_question_id = #{aq_id}, question_data = #{question_data},"
      query += " created_at = '#{Time.now.to_s(:db)}', updated_at = '#{Time.now.to_s(:db)}',"
      query += " migration_id = '#{hash[:migration_id]}', position = #{position}"
      query += " WHERE id = #{id}"
      self.connection.execute(query)
    else
      query = "INSERT INTO quiz_questions (quiz_id, quiz_group_id, assessment_question_id, question_data, created_at, updated_at, migration_id, position)"
      query += " VALUES (#{q_id}, #{g_id}, #{aq_id},#{question_data},'#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}', '#{hash[:migration_id]}', #{position})"
      id = self.connection.insert(query)
    end
    hash
  end

  def migrate_file_links
    QuizQuestionLinkMigrator.migrate_file_links_in_question(self)
  end

  def self.batch_migrate_file_links(ids)
    questions = QuizQuestion.find(:all, :include => [:quiz, :assessment_question], :conditions => ['id in (?)', ids])
    questions.each do |question|
      if question.migrate_file_links
        question.save
      end
    end
  end
end
