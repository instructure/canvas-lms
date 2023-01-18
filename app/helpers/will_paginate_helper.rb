# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require "i18n"
require "will_paginate/core_ext"
require "will_paginate/view_helpers"
require "will_paginate/view_helpers/link_renderer_base"

module WillPaginateHelper
  class AccessibleLinkRenderer < WillPaginate::ActionView::LinkRenderer
    protected

    def page_number(page)
      if page == current_page
        tag(:em, page, class: "current", "aria-label": page_title(page))
      else
        link(page, page, rel: rel_value(page), "aria-label": page_title(page))
      end
    end

    def previous_or_next_page(page, text, classname)
      title = page_title(page, classname)
      if page
        link(text, page, class: classname, "aria-label": title)
      else
        tag(:span, text, class: classname + " disabled", "aria-label": title)
      end
    end

    private

    def page_title(page, classname = nil)
      return I18n.t("Previous Page") if classname == "previous_page"
      return I18n.t("Next Page") if classname == "next_page"

      I18n.t("Page %{pageNum}", pageNum: page.to_s)
    end
  end
end
