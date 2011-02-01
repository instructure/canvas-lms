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

# <% student = student_assignment_js 
  # example_student ||= false
# %>
# var submission = <%= @submission.to_json %>;
# if(submission) { submission = submission.submission; }
# document.write('\
# <div id="instructure_embedded_page_student_view" style="margin-top: 30px; <%= !example_student ? "" : "display: none;" %>">\
  # <h2 style="margin-bottom: 0;">\
    # <img src="http://localhost:3000/images/logo_small.png" style="vertical-align: middle;"/>\
    # <a href="#"><%= @assignment.title %> -- <%= student.name %></a>\
  # </h2>\
  # <div>\
    # Due: <%= @assignment.due_at.strftime("%b %d by %I:%M%p") %><br/>\
# ');
# if(submission && (submission.grade || submission.grade === 0)) {
  # document.write('\
    # Your Score: ' + submission.grade + ' out of 20<br/>\
  # ');
# } else if (submission) {
  # document.write('\
    # Your submission hasn\'t been graded yet<br/>\
  # ');
# } else {
  # document.write('\
    # You haven\'t submitted anything for this assignment<br/>\
    # <form style="margin: 20px 0px 0px 50px;">\
    # <table style="padding: 0; margin: 0; width: auto;">\
      # <tr>\
        # <td>File Upload:</td>\
        # <td><input type="file"/></td>\
      # </tr><tr>\
        # <td colspan="2" style="text-align: right;">\
          # <input type="button" value="Submit Assignment" style="margin-top: 5px;"/>\
        # </td>\
      # </tr>\
    # </table>\
    # </form>\
  # ');
# }
# document.write('\
  # </div>\
  # <div style="text-align: right; margin-top: 20px;">\
    # <a href="">Course Home</a> | \
    # <% if example_student %>\
      # <a href="#" onclick="instructureEmbedShowStudentView(\'hide\'); return false;">Back to Teacher View</a><br/>\
    # <% end %>\
  # </div>\
# </div>\
# ');
