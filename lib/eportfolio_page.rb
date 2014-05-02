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

module EportfolioPage
  def eportfolio_page_attributes
    @portfolio.setup_defaults
    @categories = @portfolio.eportfolio_categories
    if @portfolio.grants_right?(@current_user, session, :manage)
      @recent_submissions = @current_user.submissions.order("created_at DESC").all if @current_user && @current_user == @portfolio.user
      @files = @current_user.attachments.to_a
      @folders = @current_user.active_folders_detailed.to_a
    end
    @recent_submissions ||= []
    @files ||= []
    @folders ||= []
    @attachments = []
    @page.content_sections.select {|s| s.is_a?(Hash) && s[:section_type] == 'attachment' }.each do |section|
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
    add_crumb(@portfolio.name, eportfolio_path(@portfolio))
    if @owner_view
      add_crumb(t('#crumbs.eportfolio_welcome', "Welcome to Your ePortfolio"))
    else
      add_crumb(@category.name, eportfolio_named_category_path(@portfolio.id, @category.slug))
      add_crumb(@page.name, eportfolio_named_category_entry_path(@portfolio.id, @category.slug, @page.slug))
    end
  end

end