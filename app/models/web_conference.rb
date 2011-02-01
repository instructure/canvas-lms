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

class WebConference < ActiveRecord::Base
  include SendToStream
  attr_accessible :title, :duration, :description, :conference_type, :user
  attr_readonly :context_id, :context_type
  belongs_to :context, :polymorphic => true
  has_many :web_conference_participants
  has_many :users, :through => :web_conference_participants
  has_many :invitees, :through => :web_conference_participants, :source => :user, :conditions => ['web_conference_participants.participation_type = ?', 'invitee']
  has_many :attendees, :through => :web_conference_participants, :source => :user, :conditions => ['web_conference_participants.participation_type = ?', 'attendee']
  belongs_to :user
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

  
  adheres_to_policy
  before_save :infer_conference_details

  before_create :assign_uuid
  after_save :touch_context
  
  has_a_broadcast_policy
  
  named_scope :for_context_codes, lambda { |context_codes| { 
    :conditions => {:context_code => context_codes} } 
  }

  def assign_uuid
    self.uuid ||= UUIDSingleton.instance.generate
  end
  protected :assign_uuid
  
  set_broadcast_policy do |p|
    p.dispatch :web_conference_invitation
    p.to { @new_participants }
    p.whenever { |record| 
      @new_participants && !@new_participants.empty?
    }
  end
  
  on_create_send_to_streams do
    [self.user_id] + self.web_conference_participants.map(&:user_id)
  end

  def add_user(user, type)
    return unless user
    p = self.web_conference_participants.find_or_initialize_by_web_conference_id_and_user_id(self.id, user.id)
    p.participation_type = type unless type == 'attendee' && p.participation_type == 'initiator'
    if type == 'attendee'
      self.started_at ||= Time.now
      self.save
    end
    p.save
  end
  
  def added_users
    attendees
  end
  
  def add_initiator(user)
    add_user(user, 'initiator')
  end
  def add_invitee(user)
    add_user(user, 'invitee')
  end
  def add_attendee(user)
    add_user(user, 'attendee')
  end
  
  def context_code
    read_attribute(:context_code) || "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def infer_conference_settings
  end
  
  def conference_type=(val)
    conf_type = WebConference.conference_types.detect{|t| t['name'] == val }
    if conf_type
      write_attribute(:conference_type, conf_type['name'] )
      write_attribute(:type, "#{conf_type['type'].classify}Conference" )
      conf_type['name']
    else
      nil
    end
  end
  
  def infer_conference_details
    infer_conference_settings
    self.conference_type ||= config && config['name']
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.duration ||= 30
    self.user_ids ||= (self.user_id || "").to_s
    self.added_user_ids ||= ""
    self.title ||= "#{self.context.name} Web Conference"
    self.start_at ||= self.started_at
    self.end_at ||= self.ended_at
    self.end_at ||= self.start_at + (self.duration * 60) rescue nil
    if self.started_at && self.ended_at && self.ended_at < self.started_at
      self.ended_at = self.started_at
    end
  end
  
  def initiator
    self.user
  end
  
  def available?
    !self.started_at
  end
  
  def finished?
    self.started_at && !self.active?
  end
  
  def restartable?
    Time.now <= self.started_at + duration_in_seconds
  end
  
  def duration_in_seconds
    ((self.duration || 60) * 60)
  end
  
  def running_time
    [ended_at - started_at, 60].max
  end
  
  def conference_status
    raise "not implemented"
  end
  
  def active?(force_check=false)
    if !force_check
      return true if self.start_at && self.end_at && Time.now > self.start_at && Time.now < self.end_at
      return true if self.ended_at && Time.now < self.ended_at
      return false if self.ended_at && Time.now > self.ended_at #> duration_in_seconds
      return @conference_active if @conference_active
    end
    @conference_active = (conference_status == :active)
    if @conference_active && !self.end_at
      self.ended_at = Time.now + 300
      self.save
    else
      self.ended_at = [self.ended_at || Time.now, [Time.now, (self.started_at || Time.now) + duration_in_seconds].min].max
      self.save
    end
    @conference_active
  end
  
  def presenter_key
    @presenter_key ||= "instructure_" + Digest::MD5.hexdigest([user_id, self.uuid].join(","))
  end
  
  def attendee_key
    @attendee_key ||= self.conference_key
  end
  
  def admin_join_url(user, return_to="http://www.instructure.com")
    raise "not implemented"
  end
  
  def participant_join_url(user, return_to="http://www.instructure.com")
    raise "not implemented"
  end
  
  def initiate_conference
  end
  
  def craft_url(user=nil,session=nil,return_to="http://www.instructure.com")
    user ||= self.user
    initiate_conference
    if (user == self.user || self.grants_right?(user,session,:initiate)) && !active?(true)
      admin_join_url(user, return_to)
    else
      participant_join_url(user, return_to)
    end
  end
  
  def clone_for(context, dup=nil, options={})
    dup ||= WebConference.new
    self.attributes.delete_if{|k,v| [:id, :conference_key, :user_id, :added_user_id, :started_at, :uuid, :invited_user_ids].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.context = context
    context.log_merge_result("Web Conference \"#{dup.title}\" created")
    dup
  end
  
  named_scope :after, lambda{|date|
    {:conditions => ['web_conferences.start_at IS NULL OR web_conferences.start_at > ?', date] }
  }
  
  set_policy do
    given { |user, session| self.users.include?(user) && self.cached_context_grants_right?(user, session, :read) }
    set { can :read and can :join }
    
    given { |user, session| (self.is_public rescue false) }
    set { can :read and can :join }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :create_conferences) }
    set { can :create }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_content) }
    set { can :read and can :join and can :initiate and can :create and can :delete and can :update }
  end
  
  def config
    @config ||= WebConference.config(self.class.to_s, conference_type)
  end
  
  def valid_config?
    if !config
      false
    elsif conference_type
      config['name'] == conference_type
    else
      "#{config['type'].classify}Conference" == self.class.to_s
    end
  end
  
  named_scope :active, lambda {
  }
  
  def self.conference_types
    @configs ||= (YAML.load_file(RAILS_ROOT + "/config/web_conferences.yml")[RAILS_ENV] rescue nil) || []
  end
  
  def self.config(type=nil, name=nil)
    configs ||= conference_types
    if name
      config = configs.detect{|c| c['name'] == name }
    elsif type
      config = configs.detect{|c| "#{c['type'].classify}Conference" == type }
    else
      config = configs.first
    end
  end
  
  def self.serialization_excludes; [:uuid]; end
end
