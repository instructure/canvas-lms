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

module ContentImportsHelper

  def exports_enabled?
    ContentMigration.migration_plugins(true).any?
  end

  def return_or_context_url
    if params[:return_to]
      clean_return_to(params[:return_to])
    else
      context_url(@context, :context_url)
    end
  end
  
  def error_link_or_message(string)
    if string =~ /ErrorReport(?: id)?: ?(\d+)\z/
      %{<a href="#{error_url($1)}">Error Report #{$1}</a>}.html_safe
    else
      user_content(string)
    end
  end

  def mig_id(obj)
    CC::CCHelper.create_key(obj)
  end
end
