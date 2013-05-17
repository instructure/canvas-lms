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
  belongs_to :content, :polymorphic => true
  belongs_to :context, :polymorphic => true
  belongs_to :associated_asset, :polymorphic => true
  belongs_to :context_module
  belongs_to :learning_outcome
  # This allows doing a has_many_through relationship on ContentTags for linked LearningOutcomes. (see LearningOutcomeContext)
  belongs_to :learning_outcome_content, :class_name => 'LearningOutcome', :foreign_key => :content_id
  belongs_to :cloned_item
  has_many :learning_outcome_results
  # This allows bypassing loading context for validation if we have
  # context_id and context_type set, but still allows validating when
  # context is not yet saved.
  validates_presence_of :context, :unless => proc { |tag| tag.context_id && tag.context_type }
  validates_length_of :comments, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  before_save :default_values
  after_save :update_could_be_locked
  after_save :touch_context_module
  after_save :touch_context_if_learning_outcome
  include CustomValidations
  validates_as_url :url

  attr_accessible :learning_outcome, :context, :tag_type, :mastery_score, :content_asset_string, :content, :title, :indent, :position, :url, :new_tab, :content_type

  set_policy do
    given {|user, session| self.context && self.context.grants_right?(user, session, :manage_content)}
    can :delete
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  scope :active, where("content_tags.workflow_state<>'deleted'")

  attr_accessor :skip_touch
  def touch_context_module
    ContentTag.touch_context_modules([self.context_module_id]) unless skip_touch.present?
  end
  
  def self.touch_context_modules(ids=[])
    ContextModule.where(:id => ids).update_all(:updated_at => Time.now.utc) unless ids.empty?
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
    self.content_type == 'Quiz' || self.graded?
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
    else
      self.content_type.underscore
    end
  rescue
    (self.content_type || "").underscore
  end

  def assignment
    return self.content if self.content_type == 'Assignment'
    return self.content.assignment if self.content.respond_to?(:assignment)
  end
  
  alias_method :old_content, :content
  def content
    klass = self.content_type.classify.constantize rescue nil
    klass.respond_to?("tableless?") && klass.tableless? ? nil : old_content
  end
  
  def content_or_self
    content || self
  end
  
  def update_asset_name!
    return if !self.sync_title_to_asset_title?
    correct_context = self.content && self.content.respond_to?(:context) && self.content.context == self.context
    if correct_context
      if self.content.respond_to?("name=") && self.content.respond_to?("name") && self.content.name != self.title
        self.content.update_attribute(:name, self.title)
      elsif self.content.respond_to?("title=") && self.content.title != self.title
        self.content.update_attribute(:title, self.title)
      elsif self.content.respond_to?("display_name=") && self.content.display_name != self.title
        self.content.update_attribute(:display_name, self.title)
      end
    end
  end

  def self.delete_for(asset)
    ContentTag.find_all_by_content_id_and_content_type(asset.id, asset.class.to_s).each{|t| t.destroy }
    ContentTag.find_all_by_context_id_and_context_type(asset.id, asset.class.to_s).each{|t| t.destroy }
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
        alignment = ContentTag.learning_outcome_alignments.where(alignment_conditions).first
        # then don't let them delete the link
        raise LastLinkToOutcomeNotDestroyed.new(alignment) if alignment
      end
    end

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

  def locked_for?(user, deep_check=false)
    self.context_module.locked_for?(user, self, deep_check)
  end
  
  def available_for?(user, deep_check=false)
    self.context_module.available_for?(user, self, deep_check)
  end
  
  def self.update_for(asset)
    tags = ContentTag.where(:content_id => asset, :content_type => asset.class.to_s).select([:id, :tag_type, :content_type, :context_module_id]).all
    tag_ids = tags.select{|t| t.sync_title_to_asset_title? }.map(&:id)
    module_ids = tags.select{|t| t.context_module_id }.map(&:context_module_id)
    attr_hash = {:updated_at => Time.now.utc}
    {:display_name => :title, :name => :title, :title => :title}.each do |attr, val|
      attr_hash[val] = asset.send(attr) if asset.respond_to?(attr)
    end
    attr_hash[:workflow_state] = 'deleted' if asset.respond_to?(:workflow_state) && asset.workflow_state == 'deleted'
    ContentTag.where(:id => tag_ids).update_all(attr_hash)
    ContentTag.touch_context_modules(module_ids)
  end
  
  def sync_title_to_asset_title?
    self.tag_type != "learning_outcome_association" && !['ContextExternalTool', 'Attachment'].member?(self.content_type)
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
  
  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    return nil if ( !(self.content && self.content.respond_to?(:clone_for)) && self.content_type != 'ExternalUrl' && self.content_type != 'ContextModuleSubHeader')
    options[:migrate] = true if options[:migrate] == nil
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      begin
        self.save! 
      rescue ActiveRecord::RecordInvalid => e
        if e.message =~ /Url is not a valid URL/
          self.url = URI::escape(self.url)
          self.save!
        else
          raise e
        end
      end
    end
    existing = ContentTag.active.find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, self.id)
    existing ||= ContentTag.active.find_by_context_type_and_context_id_and_cloned_item_id(context.class.to_s, context.id, self.cloned_item_id)
    return existing if existing && !options[:overwrite]
    dup ||= ContentTag.new
    dup = existing if existing && options[:overwrite]

    self.attributes.delete_if{|k,v| [:id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end

    dup.context = context
    if self.content && self.content.respond_to?(:clone_for)
      content = self.content.clone_for(context)
      content.save! if content.new_record?
      context.map_merge(self.content, content)
      dup.content = content
    end
    context.log_merge_result("Tag \"#{self.title}\" created")
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
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
  scope :learning_outcome_alignments, where(:tag_type => 'learning_outcome')
  scope :learning_outcome_links, where(:tag_type => 'learning_outcome_association', :associated_asset_type => 'LearningOutcomeGroup', :content_type => 'LearningOutcome')

  # only intended for learning outcome links
  def self.outcome_title_order_by_clause
    best_unicode_collation_key("learning_outcomes.short_description")
  end

  def self.order_by_outcome_title
    includes(:learning_outcome_content).order(outcome_title_order_by_clause)
  end
end
