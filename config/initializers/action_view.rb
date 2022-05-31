# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module NoLinksHeader
  # Max header size needs a default, since it's a noop it doesn't matter what
  def send_preload_links_header(preload_links, max_header_size: 0)
    # Intentional noop so we don't bload the headers to be too big
  end
end

# Directly put it in ActionView::Base in case that has already been loaded
ActionView::Helpers::AssetTagHelper.prepend(NoLinksHeader)
ActionView::Base.prepend(NoLinksHeader)
