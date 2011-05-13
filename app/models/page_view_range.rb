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

class PageViewRange < ActiveRecord::Base
  include Workflow
  belongs_to :context, :polymorphic => true
  serialize :data

  attr_accessible :context, :start_at, :end_at
  
  workflow do
    state :needs_re_summarization
    state :summarized
  end
  
  def re_summarize
    @hash_data = {}
    @page_view_count = 0
    @participated_count = 0
    @interaction_tally = 0
    @developer_key_count = 0
    PageView.summarize_range(context, start_at.utc, end_at.utc).each do |view|
      tally(view)
    end
    if context.is_a?(Account)
      (context.courses + context.groups).each do |sub_context|
        range = PageViewRange.find_by_context_id_and_context_type_and_start_at_and_end_at(sub_context.id, sub_context.class.to_s, start_at.utc, end_at.utc)
        tally_range(range) if range
      end
      context.sub_accounts.each do |account|
        range = PageViewRange.find_by_context_id_and_context_type_and_start_at_and_end_at(account.id, account.class.to_s, start_at.utc, end_at.utc)
        tally_range(range) if range
      end
    end
    self.page_view_count = @page_view_count
    self.page_participated_count = @participated_count
    self.total_interaction_seconds = @interaction_tally
    self.mean_interaction_seconds = (@page_view_count == 0 ? 0 : @interaction_tally.to_f / @page_view_count.to_f)
    self.developer_key_count = @developer_key_count
    self.data = @hash_data
    self.workflow_state = 'summarized'
    self.save!
    account = nil
    account = context.parent_account if context.respond_to?(:parent_account)
    account = context.account if context.respond_to?(:account)
    if account
      range = PageViewRange.find_by_context_id_and_context_type_and_start_at_and_end_at(account.id, account.class.to_s, start_at.utc, end_at.utc)
      range ||= PageViewRange.create(:context => account, :start_at => start_at.utc, :end_at => end_at.utc)
      range.mark_for_review
    end
    self
  end
  
  def mark_for_review
    self.workflow_state = 'needs_re_summarization'
    self.save!
    account = nil
    account = context.parent_account if context.respond_to?(:parent_account)
    account = context.account if context.respond_to?(:account)
    if account
      range = PageViewRange.find_by_context_id_and_context_type_and_start_at_and_end_at(account.id, account.class.to_s, start_at.utc, end_at.utc)
      range ||= PageViewRange.create(:context => account, :start_at => start_at.utc, :end_at => end_at.utc)
      range.mark_for_review
    end
  end

  def tally_range(range)
    @page_view_count += range.page_view_count
    @participated_count += range.page_participated_count
    @interaction_tally += range.total_interaction_seconds
    @developer_key_count += range.developer_key_count
    if range.data && range.data[:user_agents]
      range.data[:user_agents].each{|agent, count|
        @hash_data[:user_agents] ||= {}
        @hash_data[:user_agents][agent] ||= 0
        @hash_data[:user_agents][agent] += count
      }
    end
  end
  
  def tally(view)
    @page_view_count += 1
    @participated_count += 1 if view.contributed
    @developer_key_count += 1 if view.developer_key
    @interaction_tally += view.interaction_seconds || 5
    @hash_data[:user_agents] ||= {}
    @hash_data[:user_agents][view.user_agent] ||= 0
    @hash_data[:user_agents][view.user_agent] += 1
    view.summarized = true
    view.save
  end
  
  named_scope :for_review, lambda{
    {:conditions => ['page_view_ranges.workflow_state = ?', 'needs_re_summarization'], :order => :updated_at, :limit => 5}
  }
  named_scope :re_summarize_recent, lambda{
    {:conditions => ['page_view_ranges.start_at > ? AND page_view_ranges.updated_at < ?', 1.week.ago, 3.hours.ago], :order => :updated_at, :limit => 5 }
  }
end
