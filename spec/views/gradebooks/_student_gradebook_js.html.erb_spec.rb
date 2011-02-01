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

# <% example_student ||= false
# %>
# var assignments = <%= @assignments.to_json %>;
# if(!assignments) { assignments = []; }
# var assignmentData = {};
# var submissions = <%= @submissions.to_json %>;
# if(!submissions) { submissions = []; }
# for(i in assignments) {
  # var assignment = assignments[i].assignment;
  # for(j in submissions) {
    # var submission = submissions[j].submission;
    # if(submission.assignment_id == assignment.id) {
      # assignment.submission = submission;
    # }
  # }
  # assignmentData[assignment.id] = assignment;
# }
# document.write('\
# <div id="instructure_embedded_page_student_view" style="margin-top: 30px; <%= !example_student ? "" : "display: none;" %>">\
  # <h2 style="margin-bottom: 0;">\
    # <img src="http://localhost:3000/images/logo_small.png" style="vertical-align: middle;"/>\
    # <a href="#">Grades for <%= @student.name %></a>\
  # </h2>\
  # <div style="overflow: auto; max-height: 200px; margin-left: 30px; display: block;" id="instructure_embedded_assignment_students">\
    # <table style="width: auto;">\
      # <thead>\
        # <tr>\
          # <th style="text-align: left;">Assignment</th>\
          # <th style="min-width: 100px;">Score</th>\
          # <th style="text-align: left;">Turned In</td>\
        # </tr>\
      # </thead>\
      # <tbody>\
# ');
# for(id in assignmentData) {
# //  alert(id);
# //  document.write('<tr><td>' + id + '</td></tr>')
  # var assignment = assignmentData[id];
  # var score = '-';
  # var submitted = '-';
  # if(assignment.submission && (assignment.submission.grade || assignment.submission.grade === 0)) {
    # score = assignment.submission.grade;
  # }
  # if(assignment.submission) {
    # submitted = assignment.created_at;
  # }
  # document.write('\
        # <tr>\
          # <td style="padding: 3px 10px 3px 0px;">' + assignment.title + '</td>\
          # <td style="padding: 3px 30px; text-align: center;">' + score + '</td>\
          # <td style="padding: 3px 10px; text-align: center;">' + submitted + '</td>\
        # </tr>\
  # ');
# }
# document.write('\
      # </tbody>\
    # </table>\
  # </div>\
  # <div style="text-align: right; margin-top: 20px;">\
    # <a href="">Course Home</a> | \
    # <% if example_student %>\
      # <a href="#" onclick="instructureEmbedShowStudentView(\'hide\'); return false;">Back to Teacher View</a><br/>\
    # <% end %>\
  # </div>\
# </div>\
# ');
