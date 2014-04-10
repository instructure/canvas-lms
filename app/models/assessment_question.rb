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
  EXPORTABLE_ATTRIBUTES = [
    :id, :name, :question_data, :context_id, :context_type, :workflow_state,
    :created_at, :updated_at, :assessment_question_bank_id, :deleted_at, :position
  ]

  EXPORTABLE_ASSOCIATIONS = [:quiz_questions, :attachments, :context, :assessment_question_bank]

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
    given{|user, session| cached_context_grants_right?(user, session, :manage_assignments) }
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

  def translate_links
    # we can't translate links unless this question has a context (through a bank)
    return unless assessment_question_bank && assessment_question_bank.context

    # This either matches the id from a url like: /courses/15395/files/11454/download
    # or gets the relative path at the end of one like: /courses/15395/file_contents/course%20files/unfiled/test.jpg
    regex = Regexp.new(%{/#{context_type.downcase.pluralize}/#{context_id}/(?:files/(\\d+)/(?:download|preview)|file_contents/(course%20files/[^'"?]*))(?:\\?([^'"]*))?})
    file_substitutions = {}

    deep_translate = lambda do |obj|
      if obj.is_a?(Hash)
        obj.inject(HashWithIndifferentAccess.new) {|h,(k,v)| h[k] = deep_translate.call(v); h}
      elsif obj.is_a?(Array)
        obj.map {|v| deep_translate.call(v) }
      elsif obj.is_a?(String)
        obj.gsub(regex) do |match|
          id_or_path = $1 || $2
          if !file_substitutions[id_or_path]
            if $1
              file = Attachment.find_by_context_type_and_context_id_and_id(context_type, context_id, id_or_path)
            elsif $2
              path = URI.unescape(id_or_path)
              file = Folder.find_attachment_in_context_with_path(assessment_question_bank.context, path)
            end
            begin
              new_file = file.clone_for(self)
            rescue => e
              new_file = nil
              er = ErrorReport.log_exception(:file_clone_during_translate_links, e)
              logger.error("Error while cloning attachment during AssessmentQuestion#translate_links: id: #{self.id} error_report: #{er.id}")
            end
            new_file.save if new_file
            file_substitutions[id_or_path] = new_file
          end
          if sub = file_substitutions[id_or_path]
            query_rest = $3 ? "&#{$3}" : ''
            "/assessment_questions/#{self.id}/files/#{sub.id}/download?verifier=#{sub.uuid}#{query_rest}"
          else
            match
          end
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
        data = write_attribute(:question_data, data.with_indifferent_access)
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
    elsif self.new_record? || (quiz_questions.count <= 1 && question.assessment_question_id == self.id)
      true
    else
      false
    end
  end

  def create_quiz_question
    qq = quiz_questions.new
    qq.migration_id = self.migration_id
    qq.write_attribute(:question_data, question_data)
    qq
  end

  def self.scrub(text)
    if text && text[-1] == 191 && text[-2] == 187 && text[-3] == 239
      text = text[0..-4]
    end
    text
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end


  def self.parse_question(qdata, assessment_question=nil)
    qdata = qdata.to_hash.with_indifferent_access
    previous_data = assessment_question.question_data rescue {}
    previous_data ||= {}

    question = Quizzes::QuizQuestion::QuestionData.generate(
      id: qdata[:id] || previous_data[:id],
      regrade_option: qdata[:regrade_option] || previous_data[:regrade_option],
      points_possible: qdata[:points_possible] || previous_data[:points_possible],
      correct_comments: qdata[:correct_comments] || previous_data[:correct_comments],
      incorrect_comments: qdata[:incorrect_comments] || previous_data[:incorrect_comments],
      neutral_comments: qdata[:neutral_comments] || previous_data[:neutral_comments],
      question_type: qdata[:question_type] || previous_data[:question_type],
      question_name: qdata[:question_name] || qdata[:name] || previous_data[:question_name],
      question_text: qdata[:question_text] || previous_data[:question_text],
      answers: qdata[:answers] || previous_data[:answers],
      formulas: qdata[:formulas] || previous_data[:formulas],
      variables: qdata[:variables] || previous_data[:variables],
      answer_tolerance: qdata[:answer_tolerance] || previous_data[:answer_tolerance],
      formula_decimal_places: qdata[:formula_decimal_places] || previous_data[:formula_decimal_places],
      matching_answer_incorrect_matches: qdata[:matching_answer_incorrect_matches] || previous_data[:matching_answer_incorrect_matches],
      matches: qdata[:matches] || previous_data[:matches]
    )

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

  def self.process_migration(*args)
    Importers::AssessmentQuestionImporter.process_migration(*args)
  end

  def self.import_from_migration(*args)
    Importers::AssessmentQuestionImporter.import_from_migration(*args)
  end

  scope :active, where("assessment_questions.workflow_state<>'deleted'")
end
