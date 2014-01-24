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

module EportfoliosHelper
  def show_me(link_class)
    raw("<a href=\"#\" class=\"#{link_class}\"><b>#{h(t('#eportfolios.show_me', "show me"))}</b></a>")
  end

  def edit_icon
    "<i class='icon-edit'></i>".html_safe
  end

  def delete_icon(png=false)
    if png
      image_tag("delete.png")
    else
      raw('&#215;')
    end
  end

  def help_icon
    "<i class='icon-question'></i>".html_safe
  end

  def edit_link_text
    t('#eportfolios.edit_link_text', "%{edit_icon} Edit This Page", :edit_icon => edit_icon)
  end

  def help_link_text
    t('#eportfolios.help_link_text', "%{help_icon} How Do I...?", :help_icon => help_icon)
  end

  def manage_pages_link_text
    t('#eportfolios.manage_pages_link_text', "Organize/Manage Pages")
  end

  def manage_sections_link_text
    t('#eportfolios.manage_sections_link_text', "Organize Sections")
  end
end
