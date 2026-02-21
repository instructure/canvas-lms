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

module EportfoliosHelper
  def show_me(link_class)
    tag.a href: "#", class: link_class do
      tag.b t("#eportfolios.show_me", "show me")
    end
  end

  def edit_icon
    tag.i class: "icon-edit"
  end

  def delete_icon(png: false)
    if png
      image_tag("delete.png", alt: I18n.t("Delete"))
    else
      "&#215;".html_safe
    end
  end

  def help_icon
    tag.i class: "icon-question"
  end

  def edit_link_text
    t("#eportfolios.edit_link_text", "%{edit_icon} Edit This Page", edit_icon:)
  end

  def help_link_text
    t("#eportfolios.help_link_text", "%{help_icon} How Do I...?", help_icon:)
  end

  def manage_pages_link_text
    t("#eportfolios.manage_pages_link_text", "Organize/Manage Pages")
  end

  def manage_sections_link_text
    t("#eportfolios.manage_sections_link_text", "Organize Sections")
  end
end
