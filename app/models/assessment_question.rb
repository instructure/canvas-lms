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

class AssessmentQuestion < ActiveRecord::Base
  include Workflow
  attr_accessible :name, :question_data, :form_question_data

  has_many :quiz_questions, :class_name => 'Quizzes::QuizQuestion'
  has_many :attachments, :as => :context
  delegate :context, :context_id, :context_type, :to => :assessment_question_bank
  attr_accessor :initial_context
  belongs_to :assessment_question_bank, :touch => true
  simply_versioned :automatic => false
  acts_as_list :scope => :assessment_question_bank
  before_validation :infer_defaults
  after_save :translate_links_if_changed
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  validates_presence_of :workflow_state, :assessment_question_bank_id

  ALL_QUESTION_TYPES = ["multiple_answers_question", "fill_in_multiple_blanks_question",
                        "matching_question", "missing_word_question",
                        "multiple_choice_question", "numerical_question",
                        "text_only_question", "short_answer_question",
                        "multiple_dropdowns_question", "calculated_question",
                        "essay_question", "true_false_question", "file_upload_question"]

  serialize :question_data

  set_policy do
    given{|user, session| self.context.grants_right?(user, session, :manage_assignments) }
    can :read and can :create and can :update and can :delete
  end

  def infer_defaults
    self.question_data ||= HashWithIndifferentAccess.new
    if self.question_data.is_a?(Hash)
      if self.question_data[:question_name].try(:strip).blank?
        self.question_data[:question_name] = t :default_question_name, "Question"
      end
      self.question_data[:name] = self.question_data[:question_name]
    end
    self.name = self.question_data[:question_name] || self.name
    self.assessment_question_bank ||= AssessmentQuestionBank.unfiled_for_context(self.initial_context)
  end

  def translate_links_if_changed
    # this has to be in an after_save, because translate_links may create attachments
    # with this question as the context, and if this question does not exist yet,
    # creating that attachment will fail.
    translate_links if self.question_data_changed? && !@skip_translate_links
  end

  def self.translate_links(ids)
    ids.each do |aqid|
      if aq = AssessmentQuestion.find(aqid)
        aq.translate_links
      end
    end
  end

  def translate_link_regex
    @regex ||= Regexp.new(%{/#{context_type.downcase.pluralize}/#{context_id}/(?:files/(\\d+)/(?:download|preview)|file_contents/(course%20files/[^'"?]*))(?:\\?([^'"]*))?})
  end

  def file_substitutions
    @file_substitutions ||= {}
  end

  def translate_file_link(link, match_data=nil)
    match_data ||= link.match(translate_link_regex)
    return link unless match_data

    id = match_data[1]
    path = match_data[2]
    id_or_path = id || path

    if !file_substitutions[id_or_path]
      if id
        file = Attachment.where(context_type: context_type, context_id: context_id, id: id_or_path).first
      elsif path
        path = URI.unescape(id_or_path)
        file = Folder.find_attachment_in_context_with_path(assessment_question_bank.context, path)
      end
      begin
        new_file = file.try(:clone_for, self)
      rescue => e
        new_file = nil
        er_id = Canvas::Errors.capture_exception(:file_clone_during_translate_links, e)[:error_report]
        logger.error("Error while cloning attachment during"\
                           " AssessmentQuestion#translate_links: "\
                           "id: #{self.id} error_report: #{er_id}")
      end
      new_file.save if new_file
      file_substitutions[id_or_path] = new_file
    end
    if sub = file_substitutions[id_or_path]
      query_rest = match_data[3] ? "&#{match_data[3]}" : ''
      "/assessment_questions/#{self.id}/files/#{sub.id}/download?verifier=#{sub.uuid}#{query_rest}"
    else
      link
    end
  end

  def translate_links
    # we can't translate links unless this question has a context (through a bank)
    return unless assessment_question_bank && assessment_question_bank.context

    # This either matches the id from a url like: /courses/15395/files/11454/download
    # or gets the relative path at the end of one like: /courses/15395/file_contents/course%20files/unfiled/test.jpg

    deep_translate = lambda do |obj|
      if obj.is_a?(Hash)
        obj.inject(HashWithIndifferentAccess.new) {|h,(k,v)| h[k] = deep_translate.call(v); h}
      elsif obj.is_a?(Array)
        obj.map {|v| deep_translate.call(v) }
      elsif obj.is_a?(String)
        obj.gsub(translate_link_regex) do |match|
          translate_file_link(match, $~)
        end
      else
        obj
      end
    end

    hash = deep_translate.call(self.question_data)
    self.question_data = hash

    @skip_translate_links = true
    self.save!
    @skip_translate_links = false
  end

  def data
    res = self.question_data || HashWithIndifferentAccess.new
    res[:assessment_question_id] = self.id
    res[:question_name] = t :default_question_name, "Question" if res[:question_name].blank?
    # TODO: there's a potential id conflict here, where if a quiz
    # has some questions manually created and some pulled from a
    # bank, it's possible that a manual question's id could match
    # an assessment_question's id.  This would prevent the user
    # from being able to answer both questions when taking the quiz.
    res[:id] = self.id
    res
  end

  workflow do
    state :active
    state :independently_edited
    state :deleted
  end

  def form_question_data=(data)
    self.question_data = AssessmentQuestion.parse_question(data, self)
  end

  def question_data=(data)
    if data.is_a?(String)
      data = ActiveSupport::JSON.decode(data) rescue nil
    else
      # we may be modifying this data (translate_links), and only want to work on a copy
      data = data.try(:dup)
    end
    # force AR to think this attribute has changed
    self.question_data_will_change!
    write_attribute(:question_data, data.to_hash.with_indifferent_access)
  end

  def question_data
    if data = read_attribute(:question_data)
      if data.class == Hash
         write_attribute(:question_data, data.with_indifferent_access)
         data = read_attribute(:question_data)
      end
    end

    data
  end

  def edited_independent_of_quiz_question
    self.workflow_state = 'independently_edited'
  end

  def editable_by?(question)
    if self.independently_edited?
      false
    # If the assessment_question was created long before the quiz_question,
    # then the assessment question must have been created on its own, which means
    # it shouldn't be affected by changes to the quiz_question since it wasn't
    # based on the quiz_question to begin with
    elsif !self.new_record? && question.assessment_question_id == self.id && question.created_at && self.created_at < question.created_at + 5.minutes && self.created_at > question.created_at + 30.seconds
      false
    elsif self.assessment_question_bank && self.assessment_question_bank.title != AssessmentQuestionBank.default_unfiled_title
      false
    elsif question.is_a?(Quizzes::QuizQuestion) && question.generated?
      false
    elsif self.new_record? || (quiz_questions.count <= 1 && question.assessment_question_id == self.id)
      true
    else
      false
    end
  end

  def create_quiz_question(quiz_id)
    quiz_questions.new.tap do |qq|
      qq.write_attribute(:question_data, question_data)
      qq.quiz_id = quiz_id
      qq.workflow_state = 'generated'
      qq.save_without_callbacks
    end
  end

  def find_or_create_quiz_question(quiz_id, exclude_ids=[])
    query = quiz_questions.where(quiz_id: quiz_id).order(:id)
    query = query.where('id NOT IN (?)', exclude_ids) if exclude_ids.present?

    if qq = query.first
      qq.update_assessment_question! self
    else
      create_quiz_question(quiz_id)
    end
  end

  def self.scrub(text)
    if text && text[-1] == 191 && text[-2] == 187 && text[-3] == 239
      text = text[0..-4]
    end
    text
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    self.save
  end


  def self.parse_question(qdata, assessment_question=nil)
    qdata = qdata.to_hash.with_indifferent_access
    qdata[:question_name] ||= qdata[:name]

    previous_data = if assessment_question.present?
                      assessment_question.question_data || {}
                    else
                      {}
                    end.with_indifferent_access

    data = previous_data.merge(qdata.delete_if {|k, v| !v}).slice(
      :id, :regrade_option, :points_possible, :correct_comments, :incorrect_comments,
      :neutral_comments, :question_type, :question_name, :question_text, :answers,
      :formulas, :variables, :answer_tolerance, :formula_decimal_places,
      :matching_answer_incorrect_matches, :matches,
      :correct_comments_html, :incorrect_comments_html, :neutral_comments_html
    )

    [
      [:correct_comments_html, :correct_comments],
      [:incorrect_comments_html, :incorrect_comments],
      [:neutral_comments_html, :neutral_comments],
    ].each do |html_key, non_html_key|
      if qdata.has_key?(html_key) && qdata[html_key].blank? && qdata[non_html_key].blank?
        data.delete(non_html_key)
      end
    end

    question = Quizzes::QuizQuestion::QuestionData.generate(data)

    question[:assessment_question_id] = assessment_question.id rescue nil
    question
  end

  def self.variable_id(variable)
    Digest::MD5.hexdigest(["dropdown", variable, "instructure-key"].join(","))
  end

  def clone_for(question_bank, dup=nil, options={})
    dup ||= AssessmentQuestion.new
    self.attributes.delete_if{|k,v| [:id, :question_data].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.assessment_question_bank_id = question_bank
    dup.write_attribute(:question_data, self.question_data)
    dup
  end

  scope :active, -> { where("assessment_questions.workflow_state<>'deleted'") }
end
