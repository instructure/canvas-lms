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

# TODO: Remove this file for CANVAS_RAILS3

class String # :nodoc:
  # Backporting this from rails3 because I think it's nice
  unless method_defined?(:strip_heredoc)
    def strip_heredoc
      indent = scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
      gsub(/^[ \t]{#{indent}}/, '')
    end
  end
end
