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

class UserService < ActiveRecord::Base
  include Workflow
  
  belongs_to :user
  attr_accessor :password
  attr_accessible :user, :service, :protocol, :token, :secret, :service_user_url, :service_user_id, :service_user_name, :service_domain
  
  before_save :infer_defaults
  after_save :assert_relations
  after_save :touch_user
  after_destroy :remove_related_channels
  
  def should_have_communication_channel?
    ['facebook', 'twitter'].include?(service) && self.user
  end
  
  def assert_relations
    if should_have_communication_channel?
      cc = self.user.communication_channels.find_or_create_by_path_type(service)
      cc.path_type = service
      cc.workflow_state = 'active'
      cc.path = "#{self.service_user_id}@#{service}.com"
      cc.save!
    end
    if self.user_id && self.service
      UserService.delete_all(['user_id=? AND service=? AND id != ?', self.user_id, self.service, self.id]) rescue nil
    end
    true
  end
  
  def remove_related_channels
    if self.service == 'facebook' && self.user
      ccs = self.user.communication_channels.find_all_by_path_type('facebook')
      ccs.each{|cc| cc.destroy }
    end
    true
  end
  
  def assert_communication_channel
    self.touch if should_have_communication_channel? && !self.user.communication_channels.find_by_path_type('twitter')
  end
  
  def infer_defaults
    self.refresh_at ||= Time.now.utc
  end
  protected :infer_defaults
  
  workflow do
    state :active do
      event :failed_request, :transitions_to => :failed
    end
    
    state :failed
  end
  
  named_scope :of_type, lambda { |type| 
    { :conditions => ['user_services.type = ?', type.to_s]}
  }
  
  named_scope :to_be_polled, lambda {
    { :conditions => ['refresh_at < ?', Time.now.utc], :order => :refresh_at, :limit => 1 }
  }
  named_scope :for_user, lambda{|user|
    users = Array(user)
    {:conditions => {:user_id => users.map(&:id)} }
  }
  named_scope :for_service, lambda { |service|
    if(service.is_a?(UserService))
      { :conditions => ['user_services.service = ?', service.service]}
    else
      { :conditions => ['user_services.service = ?', service.to_s]}
    end
  }
  
  def service_name
    self.service.titleize rescue ""
  end
  
  def password=(password)
    self.crypted_password, self.password_salt = Canvas::Security.encrypt_password(password, 'instructure_user_service')
  end
  
  def decrypted_password
    return nil unless self.password_salt && self.crypted_password
    Canvas::Security.decrypt_password(self.crypted_password, self.password_salt, 'instructure_user_service')
  end
  
  def self.register(opts={})
    raise "User required" unless opts[:user]
    token = opts[:access_token] ? opts[:access_token].token : opts[:token]
    secret = opts[:access_token] ? opts[:access_token].secret : opts[:secret]
    domain = opts[:service_domain] || "google.com"
    service = opts[:service] || "google_docs"
    protocol = opts[:protocol] || "oauth"
    user_service = UserService.find_by_user_id_and_service_and_protocol(opts[:user].id, service, protocol)
    user_service ||= opts[:user].user_services.build(:service => service, :protocol => protocol)
    user_service.service_domain = domain
    user_service.token = token
    user_service.secret = secret
    user_service.service_user_id = opts[:service_user_id] if opts[:service_user_id]
    user_service.service_user_name = opts[:service_user_name] if opts[:service_user_name]
    user_service.service_user_url = opts[:service_user_url] if opts[:service_user_url]
    user_service.password = opts[:password] if opts[:password]
    user_service.type = service_type(service)
    user_service.save!
    user_service
  end
  
  def self.register_from_params(user, params={})
    opts = {}
    opts[:user] = user
    opts[:access_token] = nil
    opts[:token] = nil
    opts[:secret] = nil
    opts[:service] = params[:service]
    case opts[:service]
      when 'delicious'
        opts[:service_domain] = "delicious.com"
        opts[:protocol] = "http-auth"
        opts[:service_user_id] = params[:user_name]
        opts[:service_user_name] = params[:user_name]
        opts[:password] = params[:password]
      when 'diigo'
        opts[:service_domain] = "diigo.com"
        opts[:protocol] = "http-auth"
        opts[:service_user_id] = params[:user_name]
        opts[:service_user_name] = params[:user_name]
        opts[:password] = params[:password]
      when 'skype'
        opts[:service_domain] = "skype.com"
        opts[:service_user_id] = params[:user_name]
        opts[:service_user_name] = params[:user_name]
        opts[:protocol] = "skype"
      else
        raise "Unknown Service Type"
    end
    register(opts)
  end
  
  def has_profile_link?
    service != 'google_docs'
  end
  
  def has_readable_user_name?
    service == 'google_docs'
  end
  
  def self.sort_position(type)
    case type
    when 'google_docs'
      1
    when 'skype'
      3
    when 'twitter'
      4
    when 'facebook'
      5
    when 'delicious'
      7
    when 'diigo'
      8
    when 'linked_in'
      6
    else
      999
    end
  end
  
  def self.short_description(type)
    case type
    when 'google_docs'
      t '#user_service.descriptions.google_docs', 'Students can use Google Docs to collaborate on group projects.  Google Docs allows for real-time collaborative editing of documents, spreadsheets and presentations.'
    when 'google_calendar'
      ''
    when 'twitter'
      t '#user_service.descriptions.twitter', 'Twitter is a great resource for out-of-class communication.'
    when 'facebook'
      t '#user_service.descriptions.facebook', 'Listing your Facebook profile will let you more easily connect with friends you make in your classes and groups.'
    when 'delicious'
      t '#user_service.descriptions.delicious', 'Delicious is a collaborative link-sharing tool.  You can tag any page on the Internet for later reference.  You can also link to other users\' Delicious accounts to share links of similar interest.'
    when 'diigo'
      t '#user_service.descriptions.diigo', 'Diigo is a collaborative link-sharing tool.  You can tag any page on the Internet for later reference.  You can also link to other users\' Diigo accounts to share links of similar interest.'
    when 'linked_in'
      t '#user_service.descriptions.linked_in', 'LinkedIn is a resource for business networking.  Many of the relationships you build while in school can also be helpful once you enter the workplace.'
    when 'skype'
      t '#user_service.descriptions.skype', 'Skype is a free tool for online voice and video calls.'
    else
      ''
    end
  end
  
  def self.registration_url(type)
    case type
    when 'google_docs'
      'http://docs.google.com'
    when 'google_calendar'
      'http://calendar.google.com'
    when 'twitter'
      'http://twitter.com/signup'
    when 'facebook'
      'http://www.facebook.com'
    when 'delicious'
      'http://delicious.com/'
    when 'diigo'
      'https://secure.diigo.com/sign-up'
    when 'linked_in'
      'https://www.linkedin.com/reg/join'
    when 'skype'
      'http://www.skype.com/go/register'
    else
      nil
    end
  end
  
  def service_access_link
    if service == 'facebook' && Facebook.config && Facebook.config['canvas_name']
      "https://apps.facebook.com/#{Facebook.config['canvas_name']}"
    else
      service_user_link
    end
  end
  
  def service_user_link
    case service
      when 'google_docs'
        'http://docs.google.com'
      when 'google_calendar'
        'http://calendar.google.com'
      when 'twitter'
        "http://www.twitter.com/#{service_user_name}"
      when 'facebook'
        "http://www.facebook.com/profile.php?id=#{service_user_id}"
      when 'delicious'
        "http://www.delicious.com/#{service_user_name}"
      when 'diigo'
        "http://www.diigo.com/user/#{service_user_name}"
      when 'linked_in'
        service_user_url
      when 'skype'
        "skype:#{service_user_name}?add"
      else
        'http://www.instructure.com'
    end
  end
  
  def self.configured_services
    [:facebook, :google_docs, :twitter, :linked_in]
  end
  
  def self.configured_service?(service)
    configured_services.include?((service || "").to_sym)
  end
  
  def self.service_type(type)
    if type == 'google_docs'
      'DocumentService'
    elsif type == 'delicious' || type == 'diigo'
      'BookmarkService'
    else
      'UserService'
    end
  end
  def self.serialization_excludes; [:crypted_password, :password_salt, :token, :secret]; end
end
