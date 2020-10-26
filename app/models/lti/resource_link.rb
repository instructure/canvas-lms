# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Lti::ResourceLink < ApplicationRecord
  include Canvas::SoftDeletable

  validates :resource_link_id, presence: true
  validates :context_external_tool_id, presence: true

  belongs_to :context_external_tool
  alias_method :original_context_external_tool, :context_external_tool
  belongs_to :root_account, class_name: 'Account'

  has_many :line_items,
            inverse_of: :resource_link,
            class_name: 'Lti::LineItem',
            dependent: :destroy,
            foreign_key: :lti_resource_link_id

  before_validation :generate_resource_link_id, on: :create
  before_save :set_root_account

  def context_external_tool
    # Use 'current_external_tool' to lookup the tool in a way that is safe with
    # tool reinstallation and content migrations
    raise 'Use Lti::ResourceLink#current_external_tool to lookup associated tool'
  end

  def current_external_tool(context)
    ContextExternalTool.find_external_tool(
      original_context_external_tool.url,
      context,
      original_context_external_tool.id
    )
  end

  private

  def generate_resource_link_id
    self.resource_link_id ||= SecureRandom.uuid
  end

  def set_root_account
    self.root_account_id ||= self.original_context_external_tool&.root_account_id
  end
end
