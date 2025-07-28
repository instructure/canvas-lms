# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class BlockEditor < ActiveRecord::Base
  belongs_to :context, polymorphic: [:wiki_page]
  before_create :set_root_account_id

  alias_attribute :version, :editor_version

  LATEST_VERSION = "0.2"

  def set_root_account_id
    self.root_account_id = context&.root_account_id unless root_account_id
  end

  def viewer_iframe_html
    html = <<-HTML
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
      }
      iframe.block_editor_view {
        height: 100%;
      }
    </style>
    <iframe class='block_editor_view' src='#{Rails.application.routes.url_helpers.block_editor_path(id)}' />
    HTML
    html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
