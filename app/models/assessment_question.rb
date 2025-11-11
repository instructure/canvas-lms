# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  extend RootAccountResolver
  include Workflow

  has_many :quiz_questions, class_name: "Quizzes::QuizQuestion"
  has_many :attachments, as: :context, inverse_of: :context

  delegate :context, :context_id, :context_type, to: :assessment_question_bank
  attr_accessor :initial_context

  belongs_to :assessment_question_bank, touch: true
  simply_versioned automatic: false
  acts_as_list scope: :assessment_question_bank
  before_validation :infer_defaults
  after_save :translate_links_if_changed
  validates :name, length: { maximum: maximum_string_length, allow_nil: true }
  validates :workflow_state, :assessment_question_bank_id, presence: true
  resolves_root_account through: :context

  ALL_QUESTION_TYPES = %w[multiple_answers_question
                          fill_in_multiple_blanks_question
                          matching_question
                          missing_word_question
                          multiple_choice_question
                          numerical_question
                          text_only_question
                          short_answer_question
                          multiple_dropdowns_question
                          calculated_question
                          essay_question
                          true_false_question
                          file_upload_question].freeze

  serialize :question_data

  include MasterCourses::CollectionRestrictor

  self.collection_owner_association = :assessment_question_bank
  restrict_columns :content, [:name, :question_data]

  include LinkedAttachmentHandler

  def update_attachment_associations; end

  set_policy do
    given do |user, session|
      context.grants_right?(user, session, :manage_assignments_edit)
    end
    can :read and can :create and can :update and can :delete

    given do |user, session|
      context.grants_right?(user, session, :manage_assignments_add)
    end
    can :read and can :create

    given do |user, session|
      context.grants_right?(user, session, :manage_assignments_delete)
    end
    can :read and can :delete
  end

  def user_can_see_through_quiz_question?(user, session = nil)
    shard.activate do
      quiz_ids = quiz_questions.distinct.pluck(:quiz_id)
      quiz_ids.any? && Quizzes::Quiz.where(id: quiz_ids,
                                           context_type: "Course",
                                           context_id: Enrollment.where(user_id: user).active.select(:course_id)).to_a.any? { |q| q.grants_right?(user, session, :read) }
    end
  end

  def infer_defaults
    self.question_data ||= ActiveSupport::HashWithIndifferentAccess.new
    if self.question_data.is_a?(Hash)
      if self.question_data[:question_name].try(:strip).blank?
        self.question_data[:question_name] = t :default_question_name, "Question"
      end
      self.question_data[:name] = self.question_data[:question_name]
    end
    self.name = self.question_data[:question_name] || name
    self.assessment_question_bank ||= AssessmentQuestionBank.unfiled_for_context(initial_context)
  end

  def translate_links_if_changed
    # this has to be in an after_save, because translate_links may create attachments
    # with this question as the context, and if this question does not exist yet,
    # creating that attachment will fail.
    if saved_change_to_question_data? && !@skip_translate_links
      AssessmentQuestion.connection.after_transaction_commit do
        translate_links
      end
    end
  end

  def self.translate_links(ids)
    ids.each do |aqid|
      if (aq = AssessmentQuestion.find(aqid))
        aq.translate_links
      end
    end
  end

  def translate_link_regex
    @translate_link_regex ||= Regexp.new(%{/(courses/#{context_id}/(files/(?<course_attachment_id>\\d+~?\\d*)|file_contents/course%20files/(?<course_file_path>[A-Za-z0-9/_,.%+-]+))|users/(?<user_id>\\d+~?\\d*)/files/(?<user_attachment_id>\\d+~?\\d*)|media_attachments_iframe/(?<media_attachment_id>\\d+~?\\d*))(?<rest>[^"']+)?})
  end

  def file_substitutions
    @file_substitutions ||= {}
  end

  def translate_file_link(link, match_data = nil, migration: nil)
    match_data ||= link.match(translate_link_regex)
    return link unless match_data

    id_or_path = match_data[:media_attachment_id] || match_data[:course_attachment_id] || match_data[:user_attachment_id] || match_data[:course_file_path]

    unless file_substitutions[id_or_path]
      file = find_file_for_translation(match_data, id_or_path)

      if file&.replacement_attachment_id
        file = file.replacement_attachment
      end

      begin
        raise "User does not have access to file" unless migration || (updating_user && file&.grants_right?(updating_user, nil, :create))

        new_file = file.try(:clone_for, self)
      rescue => e
        new_file = nil
        err_id = Canvas::Errors.capture_exception(:file_clone_during_translate_links, e)[:error_report]
        logger.error("Error while cloning attachment during AssessmentQuestion#translate_links: id: #{id} error_report: #{err_id}")
      end
      new_file&.save
      file_substitutions[id_or_path] = new_file
    end

    if (sub = file_substitutions[id_or_path])
      # Split rest into path part (e.g., /download) and query string
      rest = match_data[:rest].to_s
      _, query_rest = rest.split("?", 2)
      query_rest ||= ""
      # TODO: GROW-146
      query_params = if context.root_account.feature_enabled?(:disable_file_verifier_access)
                       query_rest.blank? ? "" : "?#{query_rest}"
                     else
                       query_rest.blank? ? "?verifier=#{sub.uuid}" : "?verifier=#{sub.uuid}&#{query_rest}"
                     end

      if match_data[:media_attachment_id]
        "/media_attachments_iframe/#{sub.id}#{query_params}"
      else
        "/assessment_questions/#{id}/files/#{sub.id}/download#{query_params}"
      end
    else
      link
    end
  end

  def find_file_for_translation(match_data, id_or_path)
    if match_data[:course_attachment_id] || match_data[:user_attachment_id] || match_data[:media_attachment_id]
      Attachment.find_by(id: id_or_path)
    elsif match_data[:course_file_path]
      path = URI::DEFAULT_PARSER.unescape("course%20files/#{id_or_path}")
      Folder.find_attachment_in_context_with_path(assessment_question_bank.context, path)
    end
  end

  def translate_links(migration: nil)
    # we can't translate links unless this question has a context (through a bank)
    return unless assessment_question_bank&.context

    # This either matches the id from a url like: /courses/15395/files/11454/download
    # or gets the relative path at the end of one like: /courses/15395/file_contents/course%20files/unfiled/test.jpg

    deep_translate = lambda do |obj|
      case obj
      when Hash
        obj.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |(k, v), h|
          h[k] = deep_translate.call(v)
        end
      when Array
        obj.map { |v| deep_translate.call(v) }
      when String
        obj.gsub(translate_link_regex) do |match|
          translate_file_link(match, $~, migration:)
        end
      else
        obj
      end
    end

    hash = deep_translate.call(self.question_data)
    if hash != self.question_data
      self.question_data = hash

      @skip_translate_links = true
      save!
      @skip_translate_links = false
    end
  end

  def data
    res = self.question_data || ActiveSupport::HashWithIndifferentAccess.new
    res[:assessment_question_id] = id
    res[:question_name] = t :default_question_name, "Question" if res[:question_name].blank?
    # TODO: there's a potential id conflict here, where if a quiz
    # has some questions manually created and some pulled from a
    # bank, it's possible that a manual question's id could match
    # an assessment_question's id.  This would prevent the user
    # from being able to answer both questions when taking the quiz.
    res[:id] = id
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
    data = if data.is_a?(String)
             JSON.parse(data)
           else
             # we may be modifying this data (translate_links), and only want to work on a copy
             data&.dup
           end
    super(data.to_hash.with_indifferent_access)
  end

  def question_data
    if (data = super) && data.instance_of?(Hash)
      data = self["question_data"] = data.with_indifferent_access
    end

    data
  end

  def edited_independent_of_quiz_question
    self.workflow_state = "independently_edited"
  end

  def editable_by?(question)
    if independently_edited? ||
       # If the assessment_question was created long before the quiz_question,
       # then the assessment question must have been created on its own, which means
       # it shouldn't be affected by changes to the quiz_question since it wasn't
       # based on the quiz_question to begin with
       (!new_record? && question.assessment_question_id == id && question.created_at && created_at < question.created_at + 5.minutes && created_at > question.created_at + 30.seconds) ||
       (self.assessment_question_bank && self.assessment_question_bank.title != AssessmentQuestionBank.default_unfiled_title) ||
       (question.is_a?(Quizzes::QuizQuestion) && question.generated?)
      false
    else
      new_record? || (quiz_questions.count <= 1 && question.assessment_question_id == id)
    end
  end

  def self.find_or_create_quiz_questions(assessment_questions, quiz_id, quiz_group_id, duplicate_index = 0)
    return [] if assessment_questions.empty?

    # prepopulate version_number
    current_versions = Version.shard(Shard.shard_for(quiz_id))
                              .where(versionable_type: "AssessmentQuestion", versionable_id: assessment_questions)
                              .group(:versionable_id)
                              .maximum(:number)
    # cache all the known quiz_questions
    scope = Quizzes::QuizQuestion
            .shard(Shard.shard_for(quiz_id))
            .where(quiz_id:, workflow_state: "generated")
    # we search for nil quiz_group_id and duplicate_index to find older questions
    # generated before we added proper race condition checking
    existing_quiz_questions = scope
                              .where(assessment_question_id: assessment_questions,
                                     quiz_group_id: [nil, quiz_group_id],
                                     duplicate_index: [nil, duplicate_index])
                              .order("id, quiz_group_id NULLS LAST")
                              .group_by(&:assessment_question_id)

    assessment_questions.map do |aq|
      aq.force_version_number(current_versions[aq.id] || 0)
      qq = existing_quiz_questions[aq.id].try(:first)
      if qq
        qq.update_from_assessment_question!(aq, quiz_group_id, duplicate_index)
      else
        begin
          Quizzes::QuizQuestion.transaction(requires_new: true) do
            qq = aq.create_quiz_question(quiz_id, quiz_group_id, duplicate_index)
          end
        rescue ActiveRecord::RecordNotUnique
          qq = scope.where(assessment_question_id: aq,
                           quiz_group_id:,
                           duplicate_index:).take!
          qq.update_from_assessment_question!(aq, quiz_group_id, duplicate_index)
        end
      end
      qq
    end
  end

  def create_quiz_question(quiz_id, quiz_group_id = nil, duplicate_index = nil)
    quiz_questions.new.tap do |qq|
      qq["question_data"] = question_data
      qq.quiz_id = quiz_id
      qq.quiz_group_id = quiz_group_id
      qq.assessment_question = self
      qq.workflow_state = "generated"
      qq.duplicate_index = duplicate_index
      Quizzes::QuizQuestion.suspend_callbacks(:validate_blank_questions, :infer_defaults, :update_quiz, :update_attachment_associations) do
        qq.save!
        qq.copy_attachment_associations_from(self)
      end
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
    self.assessment_question_bank.touch
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save
  end

  def self.parse_question(qdata, assessment_question = nil)
    qdata = qdata.to_hash.with_indifferent_access
    qdata[:question_name] ||= qdata[:name]

    previous_data = if assessment_question.present?
                      assessment_question.question_data || {}
                    else
                      {}
                    end.with_indifferent_access

    data = previous_data.merge(qdata.compact).slice(
      :id,
      :regrade_option,
      :points_possible,
      :correct_comments,
      :incorrect_comments,
      :neutral_comments,
      :question_type,
      :question_name,
      :question_text,
      :answers,
      :formulas,
      :variables,
      :answer_tolerance,
      :formula_decimal_places,
      :matching_answer_incorrect_matches,
      :matches,
      :correct_comments_html,
      :incorrect_comments_html,
      :neutral_comments_html
    )

    [
      [:correct_comments_html, :correct_comments],
      [:incorrect_comments_html, :incorrect_comments],
      [:neutral_comments_html, :neutral_comments],
    ].each do |html_key, non_html_key|
      if qdata.key?(html_key) && qdata[html_key].blank? && qdata[non_html_key].blank?
        data.delete(non_html_key)
      end
    end

    question = Quizzes::QuizQuestion::QuestionData.generate(data)

    question[:assessment_question_id] = assessment_question&.id
    question
  end

  def self.variable_id(variable)
    Digest::MD5.hexdigest(["dropdown", variable, "instructure-key"].join(","))
  end

  def clone_for(question_bank, dup = nil, **)
    dup ||= AssessmentQuestion.new
    attributes.except("id", "question_data").each do |key, val|
      dup.send(:"#{key}=", val)
    end
    dup.assessment_question_bank_id = question_bank
    dup["question_data"] = question_data
    dup
  end

  scope :active, -> { where("assessment_questions.workflow_state<>'deleted'") }
end
