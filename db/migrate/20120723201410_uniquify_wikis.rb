#
# Copyright (C) 2012 - present Instructure, Inc.
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

class UniquifyWikis < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # The model no longer exists, so I can't even use it as the basis of the query
    rows = connection.select_rows("SELECT context_type, context_id FROM #{connection.quote_table_name('wiki_namespaces')} WHERE namespace='default' GROUP BY context_type, context_id HAVING COUNT(*) > 1")
    rows.each do |(context_type, context_id)|
      context = context_type.constantize.find(context_id)
      wikis = connection.select_rows("SELECT wiki_id FROM #{connection.quote_table_name('wiki_namespaces')} WHERE namespace='default' AND context_type='#{context_type}' AND context_id=#{context_id}").map(&:first).map(&:to_i)
      to_keep = context.wiki_id
      wikis.delete(to_keep)
      WikiPage.where(:wiki_id => wikis).update_all(:wiki_id => to_keep)
      Wiki.where(:id => wikis).delete_all
      connection.delete("DELETE FROM #{connection.quote_table_name('wiki_namespaces')} WHERE wiki_id IN (#{wikis.join(',')})")
    end
  end
end
