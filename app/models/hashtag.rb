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

class Hashtag < ActiveRecord::Base
  has_many :short_message_associations, :as => :context
  has_many :short_messages, :through => :short_message_associations
  
  before_save :infer_defaults
  
  def infer_defaults
    self.refresh_at ||= Time.now.utc
  end
  protected :infer_defaults
  
  def user_contexts
    res = {}
    contexts.each do |context|
      context.users.each do |user|
        res[user.id] ||= []
        res[user.id] << context
      end
    end
    res
  end
  
  def contexts
    Group.with_hashtag(self.hashtag) + Course.with_hashtag(self.hashtag)
  end
  
  def add_short_message(user, result, public=false)
    message = ShortMessage.find_by_service_message_id_and_service(result["id"], 'twitter')
    user ||= UserService.find_by_service_user_name_and_service(result["from_user"], "twitter").user rescue nil
    message ||= ShortMessage.create(
      :service_message_id => result["id"],
      :service => "twitter",
      :user => user,
      :message => result["text"],
      :created_at => Time.parse(result["created_at"]),
      :service_user_name => result["from_user"]
    )
    message.is_public ||= public
    message.save
    
    self.short_message_associations.find_or_create_by_short_message_id(message.id) if public
    contexts = user_contexts[user.id] if user
    contexts ||= []
    contexts.each do |context|
      context.short_message_associations.find_or_create_by_short_message_id(message.id)
    end
  end
  
  named_scope :to_be_polled, lambda {
    { :conditions => ['hashtags.refresh_at <= now()' ], :order => :refresh_at, :limit => 1 }
  }
end
