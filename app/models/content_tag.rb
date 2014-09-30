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
class ContentTag < ActiveRecord::Base
  class LastLinkToOutcomeNotDestroyed < StandardError
    attr_reader :alignment
    def initialize( alignment )
      super( 'Link is the last link to an aligned outcome.' +
           'Remove the alignment and then try again')
      @alignment = alignment
    end 
  end
  include Workflow
  include SearchTermHelper
  belongs_to :content, :polymorphic => true
  validates_inclusion_of :content_type, :allow_nil => true, :in => ['Attachment', 'Assignment', 'WikiPage',
    'ContextModuleSubHeader', 'Quizzes::Quiz', 'ExternalUrl', 'LearningOutcome', 'DiscussionTopic',
    'Rubric', 'ContextExternalTool', 'LearningOutcomeGroup', 'AssessmentQuestionBank', 'LiveAssessments::Assessment']
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'LearningOutcomeGroup',
    'Assignment', 'Account', 'Quizzes::Quiz']
  belongs_to :associated_asset, :polymorphic => true
  validates_inclusion_of :associated_asset_type, :allow_nil => true, :in => ['LearningOutcomeGroup']
  belongs_to :context_module
  belongs_to :learning_outcome
  # This allows doing a has_many_through relationship on ContentTags for linked LearningOutcomes. (see LearningOutcomeContext)
  belongs_to :learning_outcome_content, :class_name => 'LearningOutcome', :foreign_key => :content_id
  has_many :learning_outcome_results

  EXPORTABLE_ATTRIBUTES = [
    :id, :content_id, :content_type, :context_id, :context_type, :title, :tag, :url, :created_at, :updated_at, :comments, :tag_type, :context_module_id, :position,
    :indent, :learning_outcome_id, :context_code, :mastery_score, :rubric_association_id, :workflow_state, :cloned_item_id, :associated_asset_id, :associated_asset_type, :new_tab
  ]

  EXPORTABLE_ASSOCIATIONS = [:content, :context, :associated_asset, :context_module, :learning_outcome, :learning_outcome_results, :learning_outcome_content]
  # This allows bypassing loading context for validation if we have
  # context_id and context_type set, but still allows validating when
  # context is not yet saved.
  validates_presence_of :context, :unless => proc { |tag| tag.context_id && tag.context_type }
  validates_presence_of :workflow_state
  validates_length_of :comments, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  before_save :default_values
  after_save :update_could_be_locked
  after_save :touch_context_module_after_transaction
  after_save :touch_context_if_learning_outcome
  include CustomValidations
  validates_as_url :url

  include PolymorphicTypeOverride
  override_polymorphic_types content_type: {'Quiz' => 'Quizzes::Quiz'}

  acts_as_list :scope => :context_module

  attr_accessible :learning_outcome, :context, :tag_type, :mastery_score, :content_asset_string, :content, :title, :indent, :position, :url, :new_tab, :content_type

  set_policy do
    given {|user, session| self.context && self.context.grants_right?(user, session, :manage_content)}
    can :delete
  end
  
  workflow do
    state :active do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :active
    end
    state :deleted
  end

  alias_method :published?, :active?

  scope :active, -> { where(:workflow_state => 'active') }
  scope :not_deleted, -> { where("content_tags.workflow_state<>'deleted'") }

  attr_accessor :skip_touch
  def touch_context_module
    return true if skip_touch.present?
    ContentTag.touch_context_modules([self.context_module_id])
  end

  def touch_context_module_after_transaction
    connection.after_transaction_commit {
      touch_context_module
    }
  end
  private :touch_context_module_after_transaction
  
  def self.touch_context_modules(ids=[])
    if ids.length == 1
      ContextModule.where(id: ids).update_all(updated_at: Time.now.utc)
    elsif ids.empty?
      # do nothing
    else
      ContextModule.transaction do
        ContextModule.where(id: ids).order(:id).lock.pluck(:id)
        ContextModule.where(id: ids).update_all(updated_at: Time.now.utc)
      end
    end
    true
  end
  
  def touch_context_if_learning_outcome
    if (self.tag_type == 'learning_outcome_association' || self.tag_type == 'learning_outcome') && skip_touch.blank?
      self.context_type.constantize.where(:id => self.context_id).update_all(:updated_at => Time.now.utc)
    end
  end
  
  def default_values
    self.title ||= self.content.title rescue nil
    self.title ||= self.content.name rescue nil
    self.title ||= self.content.display_name rescue nil
    self.title ||= t(:no_title, "No title")
    self.comments ||= ""
    self.comments = "" if self.comments == "Comments"
    self.context_code = "#{self.context_type.to_s.underscore}_#{self.context_id}"
  end
  protected :default_values
  
  def context_code
    read_attribute(:context_code) || "#{self.context_type.to_s.underscore}_#{self.context_id}" rescue nil
  end
  
  def context_name
    self.context.name rescue ""
  end

  def update_could_be_locked
    ContentTag.update_could_be_locked([self]) unless skip_touch.present?
    true
  end

  def self.update_could_be_locked(tags=[])
    content_ids = {}
    tags.each do |t| 
      (content_ids[t.content_type] ||= []) << t.content_id if t.content_type && t.content_id
    end
    content_ids.each do |type, ids|
      klass = type.constantize
      if klass.new.respond_to?(:could_be_locked=)
        klass.where(:id => ids).update_all(:could_be_locked => true)
      end
    end
  end

  def confirm_valid_module_requirements
    self.context_module && self.context_module.confirm_valid_requirements
  end
  
  def scoreable?
    self.content_type_quiz? || self.graded?
  end
  
  def graded?
    return true if self.content_type == 'Assignment'
    return false unless self.content_type.constantize.column_names.include?('assignment_id') #.new.respond_to?(:assignment_id)
    return !content.assignment_id.nil? rescue false
  end

  def content_type_class
    if self.content_type == 'Assignment'
      if self.content && self.content.submission_types == 'online_quiz'
        'quiz'
      elsif self.content && self.content.submission_types == 'discussion_topic'
        'discussion_topic'
      else
        'assignment'
      end
    elsif self.content_type == 'Quizzes::Quiz'
      'quiz'
    else
      self.content_type.underscore
    end
  rescue
    (self.content_type || "").underscore
  end

  def item_class
    (self.content_type || "").gsub(/\A[A-Za-z]+::/, '') + '_' + self.content_id.to_s
  end

  def assignment
    return self.content if self.content_type == 'Assignment'
    return self.content.assignment if self.content.respond_to?(:assignment)
  end
  
  alias_method :old_content, :content
  def content
    #self.content_type = 'Quizzes::Quiz' if self.content_type == 'Quiz'
    klass = self.content_type.classify.constantize rescue nil
    klass.respond_to?("tableless?") && klass.tableless? ? nil : old_content
  end
  
  def content_or_self
    content || self
  end

  def asset_safe_title(column)
    name = self.title.to_s
    if (limit = self.content.class.try(:columns_hash)[column].try(:limit)) && name.length > limit
      name = name[0, limit][/.{0,#{limit}}/mu]
    end
    name
  end

  def self.asset_workflow_state(asset)
    if asset.respond_to?(:published?)
      if asset.respond_to?(:deleted?) && asset.deleted?
        'deleted'
      elsif asset.published?
        'active'
      else
        'unpublished'
      end
    else
      if asset.respond_to?(:workflow_state)
        workflow_state = asset.workflow_state.to_s
        if ['active', 'available', 'published'].include?(workflow_state)
          'active'
        elsif ['unpublished', 'deleted'].include?(workflow_state)
          workflow_state
        end
      else
        nil
      end
    end
  end

  def asset_workflow_state
    ContentTag.asset_workflow_state(self.content)
  end

  def asset_context_matches?
    self.content && self.content.respond_to?(:context) && self.content.context == context
  end

  def update_asset_name!
    return unless self.sync_title_to_asset_title?
    return unless self.asset_context_matches?

    # Assignment proxies name= and name to title= and title, which breaks the asset_safe_title logic
    if content.respond_to?("name=") && content.respond_to?("name") && !content.is_a?(Assignment)
      content.name = asset_safe_title('name')
    elsif content.respond_to?("title=")
      content.title = asset_safe_title('title')
    elsif content.respond_to?("display_name=")
      content.display_name = asset_safe_title('display_name')
    end
    content.save if content.changed?
  end

  def update_asset_workflow_state!
    return unless self.sync_workflow_state_to_asset?
    return unless self.asset_context_matches?
    return unless self.content && self.content.respond_to?(:publish!)

    if self.unpublished? && self.content.published? && self.content.can_unpublish?
      self.content.unpublish!
      self.class.update_for(self.content)
    elsif self.active? && !self.content.published?
      self.content.publish!
      self.class.update_for(self.content)
    end
  end

  def self.delete_for(asset)
    ContentTag.where(content_id: asset, content_type: asset.class.to_s).each{|t| t.destroy }
    ContentTag.where(context_id: asset, context_type: asset.class.to_s).each{|t| t.destroy }
  end

  alias_method :destroy!, :destroy
  def destroy
    # if it's a learning outcome link...
    if self.tag_type == 'learning_outcome_association'
      # and there are no other links to the same outcome in the same context...
      outcome = self.content
      other_link = ContentTag.learning_outcome_links.active.
        where(:context_type => self.context_type, :context_id => self.context_id, :content_id => outcome).
        where("id<>?", self).first
      if !other_link
        # and there are alignments to the outcome (in the link's context for
        # foreign links, in any context for native links)
        alignment_conditions = { :learning_outcome_id => outcome.id }
        native = outcome.context_type == self.context_type && outcome.context_id == self.context_id
        if !native
          alignment_conditions[:context_id] = self.context_id
          alignment_conditions[:context_type] = self.context_type
        end
        alignment = ContentTag.learning_outcome_alignments.active.where(alignment_conditions).first
        # then don't let them delete the link
        raise LastLinkToOutcomeNotDestroyed.new(alignment) if alignment
      end
    end

    context_module.remove_completion_requirement(id) if context_module

    self.workflow_state = 'deleted'
    self.save!

    # after deleting the last native link to an unaligned outcome, delete the
    # outcome. we do this here instead of in LearningOutcome#destroy because
    # (a) LearningOutcome#destroy *should* only ever be called from here, and
    # (b) we've already determined other_link and native
    if self.tag_type == 'learning_outcome_association' && !other_link && native
      outcome.destroy
    end

    true
  end

  def locked_for?(user, opts={})
    self.context_module.locked_for?(user, opts.merge({:tag => self}))
  end
  
  def available_for?(user, opts={})
    self.context_module.available_for?(user, opts.merge({:tag => self}))
  end
  
  def self.update_for(asset)
    tags = ContentTag.where(:content_id => asset, :content_type => asset.class.to_s).not_deleted.select([:id, :tag_type, :content_type, :context_module_id]).all
    module_ids = tags.map(&:context_module_id).compact

    # update title
    tag_ids = tags.select{|t| t.sync_title_to_asset_title? }.map(&:id)
    attr_hash = {:updated_at => Time.now.utc}
    {:display_name => :title, :name => :title, :title => :title}.each do |attr, val|
      attr_hash[val] = asset.send(attr) if asset.respond_to?(attr)
    end
    ContentTag.where(:id => tag_ids).update_all(attr_hash) unless tag_ids.empty?

    # update workflow_state
    tag_ids = tags.select{|t| t.sync_workflow_state_to_asset? }.map(&:id)
    attr_hash = {:updated_at => Time.now.utc}

    workflow_state = asset_workflow_state(asset)
    attr_hash[:workflow_state] = workflow_state if workflow_state
    ContentTag.where(:id => tag_ids).update_all(attr_hash) if attr_hash[:workflow_state] && !tag_ids.empty?

    # update the module timestamp
    ContentTag.touch_context_modules(module_ids)
  end
  
  def sync_title_to_asset_title?
    self.tag_type != "learning_outcome_association" && !['ContextExternalTool', 'Attachment'].member?(self.content_type)
  end

  def sync_workflow_state_to_asset?
    self.content_type_quiz? || ['Attachment', 'Assignment', 'WikiPage', 'DiscussionTopic'].include?(self.content_type)
  end

  def content_type_quiz?
    Quizzes::Quiz.class_names.include?(self.content_type)
  end

  def content_type_discussion?
    'DiscussionTopic' == self.content_type
  end

  def context_module_action(user, action, points=nil)
    self.context_module.update_for(user, action, self, points) if self.context_module
  end
  
  def content_asset_string
    @content_asset_string ||= "#{self.content_type.underscore}_#{self.content_id}"
  end
  
  def associated_asset_string
    @associated_asset_string ||= "#{self.associated_asset_type.underscore}_#{self.associated_asset_id}"
  end
  
  def content_asset_string=(val)
    vals = val.split("_")
    id = vals.pop
    type = Context::AssetTypes.get_for_string(vals.join("_").classify)
    if type && id && id.to_i > 0
      self.content_type = type.to_s
      self.content_id = id
    end
  end

  def has_rubric_association?
    content.respond_to?(:rubric_association) && content.rubric_association
  end
  
  scope :for_tagged_url, lambda { |url, tag| where(:url => url, :tag => tag) }
  scope :for_context, lambda { |context|
    case context
    when Account
      select("content_tags.*").
          joins("INNER JOIN (
            SELECT DISTINCT ct.id AS content_tag_id FROM content_tags AS ct
            INNER JOIN course_account_associations AS caa ON caa.course_id = ct.context_id
              AND ct.context_type = 'Course'
            WHERE caa.account_id = #{context.id}
          UNION
            SELECT ct.id AS content_tag_id FROM content_tags AS ct
            WHERE ct.context_id = #{context.id} AND context_type = 'Account')
          AS related_content_tags ON related_content_tags.content_tag_id = content_tags.id")
    else
      where(:context_type => context.class.to_s, :context_id => context)
    end
  }
  scope :learning_outcome_alignments, -> { where(:tag_type => 'learning_outcome') }
  scope :learning_outcome_links, -> { where(:tag_type => 'learning_outcome_association', :associated_asset_type => 'LearningOutcomeGroup', :content_type => 'LearningOutcome') }

  # TODO: add quizzes to this scope once the quiz visibilities view makes it into master
  scope :visible_to_students_with_da_enabled, lambda { |user_ids|
    joins("LEFT JOIN discussion_topics ON discussion_topics.id = content_tags.content_id AND content_type = 'DiscussionTopic'").
    joins("LEFT JOIN assignment_student_visibilities ON ((assignment_student_visibilities.assignment_id = content_tags.content_id AND content_type = 'Assignment')
                OR (assignment_student_visibilities.assignment_id = discussion_topics.assignment_id AND content_type = 'DiscussionTopic'))").
    where("content_tags.content_type NOT IN ('Assignment','DiscussionTopic')
           OR ((discussion_topics.id IS NOT NULL AND discussion_topics.assignment_id IS NULL)
               OR (assignment_student_visibilities.assignment_id IS NOT NULL AND assignment_student_visibilities.user_id IN (?))
              )", user_ids).
    uniq
   }

  # only intended for learning outcome links
  def self.outcome_title_order_by_clause
    best_unicode_collation_key("learning_outcomes.short_description")
  end

  def self.order_by_outcome_title
    includes(:learning_outcome_content).order(outcome_title_order_by_clause)
  end
end
