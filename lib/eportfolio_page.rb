# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module EportfolioPage
  def eportfolio_page_attributes
    GuardRail.activate(:secondary) do
      @categories = @portfolio.eportfolio_categories
      if @portfolio.grants_right?(@current_user, session, :manage)
        if @current_user && @current_user == @portfolio.user
          @recent_submissions ||= Submission.joins(:course).joins(:assignment)
                                            .where(user_id: @current_user, workflow_state: %w[submitted graded])
                                            .where.not(course: { workflow_state: %w[created claimed deleted] })
                                            .where.not(assignment: { workflow_state: %w[unpublished deleted] })
                                            .order(created_at: :desc).to_a
        end
        @files ||= @current_user.attachments.to_a
        @folders ||= @current_user.active_folders.preload(:active_sub_folders, :active_file_attachments).to_a
      end
      @recent_submissions ||= []
      @files ||= []
      @folders ||= []
      @attachments = []
      @page.content_sections.select { |s| s.is_a?(Hash) && s[:section_type] == "attachment" }.each do |section|
        begin
          attachment = @portfolio.user.attachments.find(section["attachment_id"])
        rescue ActiveRecord::RecordNotFound
          next
        end
        @attachments << attachment if attachment
      end
      @entries = @category.eportfolio_entries
      @eportfolio_view = true
      @show_left_side = true
    end
    add_crumb(@portfolio.name, eportfolio_path(@portfolio))
    if @owner_view
      add_crumb(t("#crumbs.eportfolio_welcome", "Welcome to Your ePortfolio"))
    else
      add_crumb(@category.name, eportfolio_named_category_path(@portfolio.id, @category.slug)) if @category.slug.present?
      add_crumb(@page.name, eportfolio_named_category_entry_path(@portfolio.id, @category.slug, @page.slug)) if @category.slug.present? && @page.slug.present?
    end
    if @current_user
      js_env folder_id: Folder.unfiled_folder(@current_user).id,
             context_code: @current_user.asset_string
    end

    js_env({ SKIP_ENHANCING_USER_CONTENT: true, SECTION_COUNT_IDX: @page.content_sections.count })
    js_bundle :eportfolio, :eportfolios_wizard_box
    css_bundle :tinymce
    @no_left_side_list_view = true
  end
end
