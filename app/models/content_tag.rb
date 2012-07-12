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

  attr_accessible :learning_outcome, :context, :tag_type, :mastery_score, :content_asset_string, :content, :title, :indent, :position, :url, :new_tab

  set_policy do
    given {|user, session| self.context && self.context.grants_right?(user, session, :manage_content)}
    can :delete
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  named_scope :active, lambda{
    {:conditions => ['content_tags.workflow_state != ?', 'deleted'] }
  }
  
  def touch_context_module
    ContentTag.touch_context_modules([self.context_module_id])
  end
  
  def self.touch_context_modules(ids=[])
    ContextModule.update_all({:updated_at => Time.now.utc}, {:id => ids}) unless ids.empty?
    true
  end
  
  def touch_context_if_learning_outcome
    self.context_type.constantize.update_all({:updated_at => Time.now.utc}, {:id => self.context_id}) if self.tag_type == 'learning_outcome_association' || self.tag_type == 'learning_outcome'
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
    if self.content_id && self.content_type
      klass = self.content_type.constantize
      if klass.new.respond_to?(:could_be_locked=)
        klass.update_all({:could_be_locked => true}, {:id => self.content_id})
      end
    end
    true
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
    self.workflow_state = 'deleted'
    self.save
  end
  
  def locked_for?(user, deep_check=false)
    self.context_module.locked_for?(user, self, deep_check)
  end
  
  def available_for?(user, deep_check=false)
    self.context_module.available_for?(user, self, deep_check)
  end
  
  def self.update_for(asset)
    tags = ContentTag.find(:all, :conditions => ['content_id = ? AND content_type = ?', asset.id, asset.class.to_s], :select => 'id, tag_type, content_type, context_module_id')
    tag_ids = tags.select{|t| t.sync_title_to_asset_title? }.map(&:id)
    module_ids = tags.select{|t| t.context_module_id }.map(&:context_module_id)
    attr_hash = {:updated_at => Time.now.utc}
    {:display_name => :title, :name => :title, :title => :title}.each do |attr, val|
      attr_hash[val] = asset.send(attr) if asset.respond_to?(attr)
    end
    attr_hash[:workflow_state] = 'deleted' if asset.respond_to?(:workflow_state) && asset.workflow_state == 'deleted'
    ContentTag.update_all(attr_hash, {:id => tag_ids})
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
  
  named_scope :for_tagged_url, lambda{|url, tag|
    {:conditions => ['content_tags.url = ? AND content_tags.tag = ?', url, tag] }
  }
  named_scope :for_context, lambda{|context|
    case context
    when Account
      { :select => 'content_tags.*',
        :joins => "INNER JOIN (
            SELECT DISTINCT ct.id AS content_tag_id FROM content_tags AS ct
            INNER JOIN course_account_associations AS caa ON caa.course_id = ct.context_id
              AND ct.context_type = 'Course'
            WHERE caa.account_id = #{context.id}
          UNION
            SELECT ct.id AS content_tag_id FROM content_tags AS ct
            WHERE ct.context_id = #{context.id} AND context_type = 'Account')
          AS related_content_tags ON related_content_tags.content_tag_id = content_tags.id" }
    else
      {:conditions => ['content_tags.context_type = ? AND content_tags.context_id = ?', context.class.to_s, context.id]}
    end
  }
  named_scope :include_progressions, lambda{
    { :include => {:context_module => :context_module_progressions} }
  }
  named_scope :learning_outcome_alignments, lambda{
    { :conditions => {:tag_type => 'learning_outcome'} }
  }
end
