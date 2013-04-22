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

class WikiPageComment < ActiveRecord::Base
  include Workflow
  belongs_to :user
  belongs_to :wiki_page
  belongs_to :context, :polymorphic => true
  after_create :update_wiki_page_comments_count

  attr_accessible :comments, :user_name
  
  def update_wiki_page_comments_count
    WikiPage.where(:id => self.wiki_page_id).update_all(:wiki_page_comments_count => self.wiki_page.wiki_page_comments.count)
  end
  
  workflow do
    state :current
    state :old
    state :deleted
  end

  def formatted_body(truncate=nil)
    self.extend TextHelper
    res = format_message(comments).first
    res = truncate_html(res, :max_length => truncate, :words => true) if truncate
    res
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end
  
  set_policy do
    given{|user, session| self.cached_context_grants_right?(user, session, :manage_wiki) }
    can :read and can :delete
    
    given{|user, session| self.cached_context_grants_right?(user, session, :read) }
    can :read
    
    given{|user, session| user && self.user_id == user.id }
    can :delete
    
    given{|user, session| self.wiki_page.grants_right?(user, session, :read) }
    can :read
  end
  
  scope :active, where("workflow_state<>'deleted'")
  scope :current, where(:workflow_state => :current)
  scope :current_first, order(:workflow_state)
end
