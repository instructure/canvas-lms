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

module AccountsHelper
  def show_last_batch
    @last_batch && !(@current_batch && @current_batch.importing?)
  end
    
  def print_messages(batch)
    return '' unless batch
    output = "<ul>"
    if batch.processing_errors && batch.processing_errors.length > 0
      output += "<li>Errors that prevent importing\n<ul>"
      batch.processing_errors.each do |message|
        output += "<li>#{message.first} - #{message.last}</li>"
      end
      output += "</ul>\n</li>"
    end
    if batch.processing_warnings && batch.processing_warnings.length > 0
      output += "<li>Warnings\n<ul>"
      batch.processing_warnings.each do |message|
        output += "<li>#{message.first} - #{message.last}</li>"
      end
      output += "</ul>\n</li>"
    end
    output += "</ul>"
    output
  end
  
  def print_counts(batch)
    return '' unless batch.data && batch.data[:counts]
    counts = batch.data[:counts]
    <<-EOF
    <ul>
      <li>Imported Items
        <ul>
          <li>Accounts: #{counts[:accounts]}</li>
          <li>Terms: #{counts[:terms]}</li>
          <li>Courses: #{counts[:courses]}</li>
          <li>Sections: #{counts[:sections]}</li>
          <li>Users: #{counts[:users]}</li>
          <li>Enrollments: #{counts[:enrollments]}</li>
        </ul>
      </li>
    </ul>
    EOF
  end
end
