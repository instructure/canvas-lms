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
class ContentTag < ActiveRecord::Base
  include Lti::Migratable

  class LastLinkToOutcomeNotDestroyed < StandardError
  end

  TABLED_CONTENT_TYPES = ["Attachment",
                          "Assignment",
                          "WikiPage",
                          "Quizzes::Quiz",
                          "LearningOutcome",
                          "DiscussionTopic",
                          "Rubric",
                          "ContextExternalTool",
                          "LearningOutcomeGroup",
                          "AssessmentQuestionBank",
                          "LiveAssessments::Assessment",
                          "Lti::MessageHandler"].freeze
  TABLELESS_CONTENT_TYPES = ["ContextModuleSubHeader", "ExternalUrl"].freeze
  CONTENT_TYPES = (TABLED_CONTENT_TYPES + TABLELESS_CONTENT_TYPES).freeze

  include Workflow
  include SearchTermHelper

  include MasterCourses::Restrictor
  restrict_columns :state, [:workflow_state]
  restrict_columns :content, %i[content_id url new_tab]

  belongs_to :content, polymorphic: [], exhaustive: false
  validates :content_type, inclusion: { allow_nil: true, in: CONTENT_TYPES }
  belongs_to :context, polymorphic:
      [:course,
       :learning_outcome_group,
       :assignment,
       :account,
       { quiz: "Quizzes::Quiz" }]
  belongs_to :associated_asset,
             polymorphic: [:learning_outcome_group, lti_resource_link: "Lti::ResourceLink"],
             polymorphic_prefix: true
  belongs_to :context_module
  belongs_to :learning_outcome
  # This allows doing a has_many_through relationship on ContentTags for linked LearningOutcomes. (see LearningOutcomeContext)
  belongs_to :learning_outcome_content, class_name: "LearningOutcome", foreign_key: :content_id
  has_many :learning_outcome_results
  belongs_to :root_account, class_name: "Account"

  after_create :clear_stream_items_if_module_is_unpublished

  # This allows bypassing loading context for validation if we have
  # context_id and context_type set, but still allows validating when
  # context is not yet saved.
  validates :context, presence: { unless: proc { |tag| tag.context_id && tag.context_type } }
  validates :workflow_state, presence: true
  validates :comments, length: { maximum: maximum_text_length, allow_blank: true }
  before_save :associate_external_tool
  before_save :default_values
  before_save :set_root_account
  before_save :update_could_be_locked
  after_save :touch_context_module_after_transaction
  after_save :touch_context_if_learning_outcome
  after_save :run_submission_lifecycle_manager_for_quizzes_next
  after_save :clear_discussion_stream_items
  after_save :send_items_to_stream
  after_save :clear_total_outcomes_cache
  after_save :update_course_pace_module_items
  after_save :update_module_item_submissions
  after_create :update_outcome_contexts

  include CustomValidations
  validates_as_url :url

  validate :check_for_restricted_content_changes

  acts_as_list scope: :context_module

  set_policy do
    #################### Begin legacy permission block #########################
    given do |user, session|
      user && !root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context&.grants_right?(user, session, :manage_content)
    end
    can :delete
    ##################### End legacy permission block ##########################

    given do |user, session|
      user && root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context&.grants_right?(user, session, :manage_course_content_delete)
    end
    can :delete
  end

  workflow do
    state :active do
      event :unpublish, transitions_to: :unpublished
    end
    state :unpublished do
      event :publish, transitions_to: :active
    end
    state :deleted
  end

  alias_method :published?, :active?

  scope :active, -> { where(workflow_state: "active") }
  scope :not_deleted, -> { where("content_tags.workflow_state<>'deleted'") }
  scope :nondeleted, -> { not_deleted }

  attr_accessor :skip_touch
  attr_accessor :reassociate_external_tool

  def touch_context_module
    return true if skip_touch.present? || context_module_id.nil?

    ContentTag.touch_context_modules([context_module_id])
  end

  def touch_context_module_after_transaction
    self.class.connection.after_transaction_commit do
      touch_context_module
    end
  end
  private :touch_context_module_after_transaction

  def self.touch_context_modules(ids = [])
    if ids.length == 1
      ContextModule.where(id: ids).not_recently_touched.update_all(updated_at: Time.now.utc)
    elsif ids.empty?
      # do nothing
    else
      ContextModule.where(id: ids).not_recently_touched.touch_all
    end
    true
  end

  def self.polymorphic_class_for(name)
    return nil if TABLELESS_CONTENT_TYPES.include?(name)

    super
  end

  def touch_context_if_learning_outcome
    if (tag_type == "learning_outcome_association" || tag_type == "learning_outcome") && skip_touch.blank?
      context_type.constantize.where(id: context_id).update_all(updated_at: Time.now.utc)
    end
  end

  def update_outcome_contexts
    return unless tag_type == "learning_outcome_association"

    if context_type == "Account" || context_type == "Course"
      content.add_root_account_id_for_context!(context)
    end
  end

  def associate_external_tool
    return if context.blank? || url.blank? || content_type != "ContextExternalTool"

    if reassociate_external_tool
      # set only when editing module item to allow changing the url,
      # which will force a lookup of the new correct tool
      # IF the url is potentially for a different tool.
      old_url_host = Addressable::URI.parse(url_was)&.host
      new_url_host = Addressable::URI.parse(url)&.host
      if old_url_host != new_url_host
        set_content_from_external_tool
      end

      return
    end

    # happy path
    return if content.present?

    set_content_from_external_tool
  end

  def set_content_from_external_tool
    content = ContextExternalTool.find_external_tool(url, context)
    self.content = content if content
  end

  def default_values
    self.title ||= content.title rescue nil
    self.title ||= content.name rescue nil
    self.title ||= content.display_name rescue nil
    self.title ||= t(:no_title, "No title")
    self.comments ||= ""
    self.comments = "" if self.comments == "Comments"
    self.context_code = "#{context_type.to_s.underscore}_#{context_id}"
  end
  protected :default_values

  def context_code
    read_attribute(:context_code) || "#{context_type.to_s.underscore}_#{context_id}" rescue nil
  end

  def context_name
    context.name rescue ""
  end

  def update_could_be_locked
    ContentTag.update_could_be_locked([self]) unless skip_touch.present?
    true
  end

  def self.update_could_be_locked(tags = [])
    content_ids = {}
    tags.each do |t|
      (content_ids[t.content_type] ||= []) << t.content_id if t.content_type && t.content_id
    end
    content_ids.each do |type, ids|
      next if TABLELESS_CONTENT_TYPES.include?(type)

      klass = type.constantize
      next unless klass < ActiveRecord::Base

      next unless klass.new.respond_to?(:could_be_locked=)

      ids.sort.each_slice(1000) do |slice|
        klass.where(id: slice).update_all_locked_in_order(could_be_locked: true)
      end
    end
  end

  def confirm_valid_module_requirements
    context_module&.confirm_valid_requirements
  end

  def scoreable?
    content_type_quiz? || graded?
  end

  def graded?
    return true if content_type == "Assignment"
    return false if content_type == "WikiPage"
    return false unless can_have_assignment?

    content && !content.assignment_id.nil?
  end

  def duplicate_able?
    case content_type_class
    when "assignment"
      content&.can_duplicate?
    when "discussion_topic", "wiki_page"
      true
    else
      false
    end
  end

  def direct_shareable?
    content_id.to_i > 0 && direct_share_type
  end

  def direct_share_type
    ContentShare::CLASS_NAME_TO_TYPE[content_type]
  end

  def direct_share_select_class
    direct_share_type.pluralize
  end

  def content_type_class(is_student = false)
    case content_type
    when "Assignment"
      if content && content.submission_types == "online_quiz"
        is_student ? "lti-quiz" : "quiz"
      elsif content && content.submission_types == "discussion_topic"
        "discussion_topic"
      elsif self&.content&.quiz_lti?
        "lti-quiz"
      else
        "assignment"
      end
    when "Quizzes::Quiz"
      is_student ? "lti-quiz" : "quiz"
    else
      content_type.underscore
    end
  rescue
    (content_type || "").underscore
  end

  def item_class
    (content_type || "").gsub(/\A[A-Za-z]+::/, "") + "_" + content_id.to_s
  end

  def can_have_assignment?
    ["Assignment", "DiscussionTopic", "Quizzes::Quiz", "WikiPage"].include?(content_type)
  end

  def assignment
    if content_type == "Assignment"
      content
    elsif can_have_assignment?
      content&.assignment
    else
      nil
    end
  end

  def content
    TABLELESS_CONTENT_TYPES.include?(content_type) ? nil : super
  end

  def content_or_self
    content || self
  end

  def asset_safe_title(column)
    name = self.title.to_s
    if (limit = content.class.try(:columns_hash)[column].try(:limit)) && name.length > limit
      name = name[0, limit][/.{0,#{limit}}/mu]
    end
    name
  end

  def self.asset_workflow_state(asset)
    if asset.respond_to?(:published?)
      if asset.respond_to?(:deleted?) && asset.deleted?
        "deleted"
      elsif asset.published?
        "active"
      else
        "unpublished"
      end
    elsif asset.respond_to?(:workflow_state)
      workflow_state = asset.workflow_state.to_s
      if %w[active available published].include?(workflow_state)
        "active"
      elsif ["unpublished", "deleted"].include?(workflow_state)
        workflow_state
      end
    else
      nil
    end
  end

  def asset_workflow_state
    ContentTag.asset_workflow_state(content)
  end

  def asset_context_matches?
    content.respond_to?(:context) && content.context == context
  end

  def update_asset_name!(user = nil)
    return unless sync_title_to_asset_title?
    return unless asset_context_matches?

    # Assignment proxies name= and name to title= and title, which breaks the asset_safe_title logic
    if content.respond_to?(:name=) && content.respond_to?(:name) && !content.is_a?(Assignment)
      content.name = asset_safe_title("name")
    elsif content.respond_to?(:title=)
      content.title = asset_safe_title("title")
    elsif content.respond_to?(:display_name=)
      content.display_name = asset_safe_title("display_name")
    end
    if content.changed?
      content.user = user if user && content.is_a?(WikiPage)
      content.save
    end
  end

  def update_asset_workflow_state!
    return unless sync_workflow_state_to_asset?
    return unless asset_context_matches?
    return unless content.respond_to?(:publish!)

    # update the asset and also update _other_ content tags that point at it
    if unpublished? && content.published? && content.can_unpublish?
      content.unpublish!
      self.class.update_for(content, exclude_tag: self)
    elsif active? && !content.published?
      content.publish!
      self.class.update_for(content, exclude_tag: self)
    end
  end

  def self.delete_for(asset)
    ContentTag.where(content_id: asset, content_type: asset.class.to_s).each(&:destroy)
    ContentTag.where(context_id: asset, context_type: asset.class.to_s).each(&:destroy)
  end

  def can_destroy?
    # if it's a learning outcome link...
    if tag_type == "learning_outcome_association"
      # and there are no other links to the same outcome in the same context...
      outcome = content
      other_link = ContentTag.learning_outcome_links.active
                             .where(context_type:, context_id:, content_id: outcome)
                             .where.not(id: self).take
      unless other_link
        # and there are alignments to the outcome (in the link's context for
        # foreign links, in any context for native links)
        alignment_conditions = { learning_outcome_id: outcome.id }
        native = outcome.context_type == context_type && outcome.context_id == context_id
        if native
          @should_destroy_outcome = true
        else
          alignment_conditions[:context_id] = context_id
          alignment_conditions[:context_type] = context_type
        end

        @active_alignment_tags = ContentTag.learning_outcome_alignments.active.where(alignment_conditions)
        if @active_alignment_tags.exists?
          # then don't let them delete the link
          return false
        end
      end
    end
    true
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    unless can_destroy?
      aligned_outcome = @active_alignment_tags.map(&:learning_outcome).first.short_description
      raise LastLinkToOutcomeNotDestroyed, "Outcome '#{aligned_outcome}' cannot be deleted because it is aligned to content."
    end

    context_module&.remove_completion_requirement(id)

    self.workflow_state = "deleted"
    save!

    # for outcome links delete the associated friendly description
    delete_outcome_friendly_description if content_type == "LearningOutcome"

    run_submission_lifecycle_manager_for_quizzes_next(force: true)
    update_module_item_submissions(change_of_module: false)

    # after deleting the last native link to an unaligned outcome, delete the
    # outcome. we do this here instead of in LearningOutcome#destroy because
    # (a) LearningOutcome#destroy *should* only ever be called from here, and
    # (b) we've already determined other_link and native
    if @should_destroy_outcome
      content.destroy
    end

    true
  end

  def locked_for?(user, opts = {})
    return false unless context_module && !context_module.deleted?

    context_module.locked_for?(user, opts.merge({ tag: self }))
  end

  def available_for?(user, opts = {})
    context_module.available_for?(user, opts.merge({ tag: self }))
  end

  def send_items_to_stream
    if content_type == "DiscussionTopic" && saved_change_to_workflow_state? && workflow_state == "active"
      content.send_items_to_stream
    end
  end

  def clear_discussion_stream_items
    if content_type == "DiscussionTopic" && (saved_change_to_workflow_state? &&
         ["active", nil].include?(workflow_state_before_last_save) &&
         workflow_state == "unpublished")
      content.clear_stream_items
    end
  end

  def clear_stream_items_if_module_is_unpublished
    if content_type == "DiscussionTopic" && context_module&.workflow_state == "unpublished"
      content.clear_stream_items
    end
  end

  def self.update_for(asset, exclude_tag: nil)
    tags = ContentTag.where(content_id: asset, content_type: asset.class.to_s).not_deleted
    tags = tags.where("content_tags.id<>?", exclude_tag.id) if exclude_tag
    tags = tags.select(%i[id tag_type content_type context_module_id]).to_a
    return if tags.empty?

    module_ids = tags.filter_map(&:context_module_id)

    # update title
    tag_ids = tags.select(&:sync_title_to_asset_title?).map(&:id)
    attr_hash = { updated_at: Time.now.utc }
    { display_name: :title, name: :title, title: :title }.each do |attr, val|
      attr_hash[val] = asset.send(attr) if asset.respond_to?(attr)
    end
    ContentTag.where(id: tag_ids).update_all(attr_hash) unless tag_ids.empty?

    # update workflow_state
    tag_ids = tags.select(&:sync_workflow_state_to_asset?).map(&:id)
    attr_hash = { updated_at: Time.now.utc }

    workflow_state = asset_workflow_state(asset)
    attr_hash[:workflow_state] = workflow_state if workflow_state
    ContentTag.where(id: tag_ids).update_all(attr_hash) if attr_hash[:workflow_state] && !tag_ids.empty?

    # update the module timestamp
    ContentTag.touch_context_modules(module_ids)
  end

  def sync_title_to_asset_title?
    tag_type != "learning_outcome_association" && !["ContextExternalTool", "Attachment"].member?(content_type)
  end

  def sync_workflow_state_to_asset?
    content_type_quiz? || %w[Attachment Assignment WikiPage DiscussionTopic].include?(content_type)
  end

  def content_type_quiz?
    Quizzes::Quiz.class_names.include?(content_type)
  end

  def content_type_discussion?
    content_type == "DiscussionTopic"
  end

  def context_module_action(user, action, points = nil)
    GuardRail.activate(:primary) do
      context_module&.update_for(user, action, self, points)
    end
  end

  def progression_for_user(user)
    context_module.context_module_progressions.where(user_id: user.id).first
  end

  def content_asset_string
    @content_asset_string ||= "#{content_type.underscore}_#{content_id}"
  end

  def associated_asset_string
    @associated_asset_string ||= "#{associated_asset_type.underscore}_#{associated_asset_id}"
  end

  def content_asset_string=(val)
    vals = val.split("_")
    id = vals.pop
    type = Context.asset_type_for_string(vals.join("_").classify)
    if type && id && id.to_i > 0
      self.content_type = type.to_s
      self.content_id = id
    end
  end

  def has_rubric_association?
    content.respond_to?(:rubric_association) && !!content.rubric_association&.active?
  end

  scope :for_tagged_url, ->(url, tag) { where(url:, tag:) }
  scope :for_context, lambda { |context|
    case context
    when Account
      where(context:).union(for_associated_courses(context))
    else
      where(context:)
    end
  }
  scope :for_associated_courses, lambda { |account|
    select("DISTINCT content_tags.*").joins("INNER JOIN
      #{CourseAccountAssociation.quoted_table_name} AS caa
      ON caa.course_id = content_tags.context_id AND content_tags.context_type = 'Course'
      AND caa.account_id = #{account.id}")
  }
  scope :learning_outcome_alignments, -> { where(tag_type: "learning_outcome") }
  scope :learning_outcome_links, -> { where(tag_type: "learning_outcome_association", associated_asset_type: "LearningOutcomeGroup", content_type: "LearningOutcome") }

  # Scopes For Differentiated Assignment Filtering:

  scope :visible_to_students_in_course_with_da, lambda { |user_ids, course_ids|
    differentiable_classes = ["Assignment", "DiscussionTopic", "Quiz", "Quizzes::Quiz", "WikiPage"]
    scope = for_non_differentiable_classes(course_ids, differentiable_classes)

    cyoe_courses, non_cyoe_courses = Course.where(id: course_ids).partition { |course| ConditionalRelease::Service.enabled_in_context?(course) }
    if non_cyoe_courses.any?
      scope = scope.union(where(context_id: non_cyoe_courses, context_type: "Course", content_type: "WikiPage"))
    end
    if cyoe_courses.any?
      scope = scope.union(
        for_non_differentiable_wiki_pages(cyoe_courses.map(&:id)),
        for_differentiable_wiki_pages(user_ids, cyoe_courses.map(&:id))
      )
    end
    scope.union(
      for_non_differentiable_discussions(course_ids)
        .merge(DiscussionTopic.visible_to_student_sections(user_ids)),
      for_differentiable_assignments(user_ids, course_ids),
      for_differentiable_discussions(user_ids, course_ids)
        .merge(DiscussionTopic.visible_to_student_sections(user_ids)),
      for_differentiable_quizzes(user_ids, course_ids)
    )
  }

  scope :for_non_differentiable_classes, lambda { |course_ids, differentiable_classes|
    where(context_id: course_ids, context_type: "Course").where.not(content_type: differentiable_classes)
  }

  scope :for_non_differentiable_discussions, lambda { |course_ids|
    joins("JOIN #{DiscussionTopic.quoted_table_name} as discussion_topics ON discussion_topics.id = content_tags.content_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND content_tags.content_type = 'DiscussionTopic'
             AND discussion_topics.assignment_id IS NULL",
             course_ids)
  }

  scope :for_non_differentiable_wiki_pages, lambda { |course_ids|
    joins("JOIN #{WikiPage.quoted_table_name} as wp ON wp.id = content_tags.content_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND content_tags.content_type = 'WikiPage'
             AND wp.assignment_id IS NULL",
             course_ids)
  }

  scope :for_differentiable_quizzes, lambda { |user_ids, course_ids|
    joins("JOIN #{Quizzes::QuizStudentVisibility.quoted_table_name} as qsv ON qsv.quiz_id = content_tags.content_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND qsv.course_id IN (?)
             AND content_tags.content_type in ('Quiz', 'Quizzes::Quiz')
             AND qsv.user_id = ANY( '{?}'::INT8[] )
        ",
             course_ids,
             course_ids,
             user_ids)
  }

  scope :for_differentiable_assignments, lambda { |user_ids, course_ids|
    joins("JOIN #{AssignmentStudentVisibility.quoted_table_name} as asv ON asv.assignment_id = content_tags.content_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND asv.course_id IN (?)
             AND content_tags.content_type = 'Assignment'
             AND asv.user_id = ANY( '{?}'::INT8[] )
        ",
             course_ids,
             course_ids,
             user_ids)
  }

  scope :for_differentiable_discussions, lambda { |user_ids, course_ids|
    joins("JOIN #{DiscussionTopic.quoted_table_name} ON discussion_topics.id = content_tags.content_id
           AND content_tags.content_type = 'DiscussionTopic'")
      .joins("JOIN #{AssignmentStudentVisibility.quoted_table_name} as asv ON asv.assignment_id = discussion_topics.assignment_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND asv.course_id IN (?)
             AND content_tags.content_type = 'DiscussionTopic'
             AND discussion_topics.assignment_id IS NOT NULL
             AND asv.user_id = ANY( '{?}'::INT8[] )
      ",
             course_ids,
             course_ids,
             user_ids)
  }

  scope :for_differentiable_wiki_pages, lambda { |user_ids, course_ids|
    joins("JOIN #{WikiPage.quoted_table_name} as wp on wp.id = content_tags.content_id
           AND content_tags.content_type = 'WikiPage'")
      .joins("JOIN #{AssignmentStudentVisibility.quoted_table_name} as asv on asv.assignment_id = wp.assignment_id")
      .where("content_tags.context_id IN (?)
             AND content_tags.context_type = 'Course'
             AND asv.course_id in (?)
             AND content_tags.content_type = 'WikiPage'
             AND wp.assignment_id IS NOT NULL
             AND asv.user_id = ANY( '{?}'::INT8[] )
      ",
             course_ids,
             course_ids,
             user_ids)
  }

  scope :can_have_assignment, -> { where(content_type: ["Assignment", "DiscussionTopic", "Quizzes::Quiz", "WikiPage"]) }

  # only intended for learning outcome links
  def self.outcome_title_order_by_clause
    best_unicode_collation_key("learning_outcomes.short_description")
  end

  def self.order_by_outcome_title
    eager_load(:learning_outcome_content).order(outcome_title_order_by_clause)
  end

  # Used to either Just-In-Time migrate a ContentTag to fully support 1.3 or
  # as part of a backfill job to migrate existing 1.3 ContentTags to fully
  # support 1.3. Fully support in this case means the associated resource link
  # has the LTI 1.1 resource_link_id stored on it. Will only migrate tags that
  # are module items that are associated with ContextExternalTools.
  # @see Lti::Migratable
  def migrate_to_1_3_if_needed!(tool)
    return if !tool&.use_1_3? || associated_asset_lti_resource_link&.lti_1_1_id.present?

    return unless context_module_id.present? && content_type == ContextExternalTool.to_s

    # Updating a 1.3 module item
    if associated_asset_lti_resource_link.present? && content&.use_1_3?
      associated_asset_lti_resource_link.update!(lti_1_1_id: tool.opaque_identifier_for(self))
    # Migrating a 1.1 module item
    elsif !content&.use_1_3?
      rl = Lti::ResourceLink.create_with(context, tool, nil, url, lti_1_1_id: tool.opaque_identifier_for(self))
      update!(associated_asset: rl, content: tool)
    end
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.directly_associated_items(tool_id)
    ContentTag.nondeleted.where(tag_type: :context_module, content_id: tool_id)
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.indirectly_associated_items(_tool_id)
    # TODO: this does not account for content tags that _are_ linked to a
    # tool and the tag has a content_id, but the content_id doesn't match
    # the current tool
    ContentTag.nondeleted.where(tag_type: :context_module, content_id: nil)
  end

  # @param [Array<Integer>] ids The IDs of the resources to fetch for this batch
  # @see Lti::Migratable
  def self.fetch_direct_batch(ids, &)
    ContentTag
      .where(id: ids)
      .preload(:associated_asset, :context)
      .find_each(&)
  end

  # @param [Integer] tool_id The ID of the LTI 1.1 tool that the resource is indirectly
  # associated with
  # @param [Array<Integer>] ids The IDs of the resources to fetch for this batch
  # @see Lti::Migratable
  def self.fetch_indirect_batch(tool_id, new_tool_id, ids)
    ContentTag
      .where(id: ids)
      .preload(:associated_asset, :context)
      .find_each do |item|
      possible_tool = ContextExternalTool.find_external_tool(item.url, item.context, nil, new_tool_id)
      next if possible_tool.nil? || possible_tool.id != tool_id

      yield item
    end
  end

  def visible_to_user?(user, opts = nil, session = nil)
    return false unless context_module

    opts ||= context_module.visibility_for_user(user, session)
    return false unless opts[:can_read]

    return true if opts[:can_read_as_admin]
    return false unless published?

    if assignment
      assignment.visible_to_user?(user, opts)
    elsif content_type_quiz?
      content.visible_to_user?(user, opts)
    else
      true
    end
  end

  def mark_as_importing!(migration)
    @importing_migration = migration
  end

  def check_for_restricted_content_changes
    if !new_record? && title_changed? && !@importing_migration && content && content.respond_to?(:is_child_content?) &&
       content.is_child_content? && content.editing_restricted?(:content)
      errors.add(:title, "cannot change title - associated content locked by Master Course")
    end
  end

  def run_submission_lifecycle_manager_for_quizzes_next(force: false)
    # Quizzes next should ideally only ever be attached to an
    # assignment.  Let's ignore any other contexts.
    return unless context_type == "Assignment"

    SubmissionLifecycleManager.recompute(context) if content.try(:quiz_lti?) && (force || workflow_state != "deleted")
  end

  def set_root_account
    return if root_account_id.present?

    self.root_account_id = case context
                           when Account
                             context.resolved_root_account_id
                           else
                             context&.root_account_id
                           end
  end

  def quiz_lti
    @quiz_lti ||= (has_attribute?(:content_type) && content_type == "Assignment") ? content&.quiz_lti? : false
  end

  def to_json(options = {})
    super({ methods: :quiz_lti }.merge(options))
  end

  def as_json(options = {})
    super({ methods: :quiz_lti }.merge(options))
  end

  def clear_total_outcomes_cache
    return unless tag_type == "learning_outcome_association" && associated_asset_type == "LearningOutcomeGroup"

    clear_context = (context_type == "LearningOutcomeGroup") ? nil : context
    Outcomes::LearningOutcomeGroupChildren.new(clear_context).clear_total_outcomes_cache
  end

  def delete_outcome_friendly_description
    OutcomeFriendlyDescription.active.find_by(context:, learning_outcome_id: content_id)&.destroy
  end

  def update_course_pace_module_items
    return unless tag_type == "context_module"

    course = context.is_a?(Course) ? context : context.try(:course)
    return unless course&.account&.feature_enabled?(:course_paces) && course.enable_course_paces

    course.course_paces.published.find_each do |course_pace|
      cpmi = course_pace.course_pace_module_items.find_by(module_item_id: id)
      cpmi ||= course_pace.course_pace_module_items.create(module_item_id: id, duration: 0) unless deleted?
      # Course paces takes over how and when assignment overrides are managed so if we are deleting an assignment from
      # a module we need to reset it back to an untouched state with regards to overrides.
      if deleted?
        cpmi&.destroy
        cpmi&.module_item&.assignment&.assignment_overrides&.destroy_all
      elsif !cpmi.valid?
        cpmi&.destroy
      end

      # Republish the course pace if changes were made
      course_pace.create_publish_progress if deleted? || cpmi.destroyed? || cpmi.saved_change_to_id? || saved_change_to_position?
    end
  end

  def update_module_item_submissions(change_of_module: true)
    return unless Account.site_admin.feature_enabled?(:differentiated_modules)

    return unless tag_type == "context_module" && (content_type == "Assignment" || content_type == "Quizzes::Quiz")

    if change_of_module
      return unless saved_change_to_context_module_id? && AssignmentOverride.active.where(context_module_id: saved_change_to_context_module_id).exists?
    else
      return unless context_module.assignment_overrides.active.exists?
    end

    content.clear_cache_key(:availability)

    if content_type == "Assignment"
      SubmissionLifecycleManager.recompute(content, update_grades: true)
    elsif content_type == "Quizzes::Quiz" && content.assignment
      content.assignment.clear_cache_key(:availability)
      SubmissionLifecycleManager.recompute(content.assignment, update_grades: true)
    end
  end

  def trigger_publish!
    enable_publish_at = context.root_account.feature_enabled?(:scheduled_page_publication)
    if unpublished? && (!content.respond_to?(:can_publish?) || content&.can_publish?)
      if content_type == "Attachment"
        content.set_publish_state_for_usage_rights
        content.save!
        publish if content.published?
      else
        publish unless enable_publish_at && content.respond_to?(:publish_at) && content.publish_at
      end
    end

    update_asset_workflow_state!
  end

  def trigger_unpublish!
    if published? && (!content.respond_to?(:can_unpublish?) || content&.can_unpublish?)
      if content_type == "Attachment"
        content.locked = true
        content.save!
      end
      unpublish
    end

    update_asset_workflow_state!
  end
end
