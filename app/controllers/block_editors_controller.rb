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

class BlockEditorsController < ApplicationController
  before_action :load_block_editor, only: [:show]

  def show
    if @block_editor.context.grants_right?(@current_user, :read)
      @exclude_account_js = true
      @embeddable = true

      block_editor = BlockEditor.find(params[:id])
      js_env block_editor_attributes: {
        id: block_editor.id,
        version: block_editor.editor_version,
        blocks: block_editor.blocks,
      }.to_json
      js_bundle :block_editor_iframe_content

      render html: "<div id='block_editor_viewer_container'>#{I18n.t("Loading...")}</div>".html_safe,
             layout: "layouts/bare"
    else
      render "shared/unauthorized", status: :unauthorized, layout: "layouts/bare"
    end
  end

  def load_block_editor
    @block_editor = BlockEditor.find(params[:id])
  end
end
