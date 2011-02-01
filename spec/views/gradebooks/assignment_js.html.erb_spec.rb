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

# var submissions = <%= @submissions.to_json %>;
# if(!submissions) { submissions = []; }
# var submissionData = {};
# var tally = 0.0;
# var total = 0.0;
# for(i in submissions) {
  # var submission = submissions[i].submission;
  # submissionData[submission.student_id] = submission;
  # if(submission.grade || submission.grade === 0) {
    # tally++;
    # total += submission.grade;
  # }
# }
# var averageScore = total / tally;
# averageScore = Math.round(averageScore * 10) / 10.0;
# if(isNaN(averageScore) || !isFinite(averageScore)) { averageScore = "N/A"; }
# function instructureEmbedToggleStudentScores(obj) {
  # var scores = document.getElementById('instructure_embedded_assignment_students');
  # if(scores.style.display != "block") {
    # scores.style.display = "block";
    # obj.innerHTML = obj.innerHTML.replace("Show", "Hide");
  # } else {
    # scores.style.display = "none";
    # obj.innerHTML = obj.innerHTML.replace("Hide", "Show");
  # }
# }
# document.write('\
# <div id="instructure_embedded_page_content" style="margin-top: 30px;">\
  # <h2 style="margin-bottom: 0;">\
    # <img src="http://localhost:3000/images/logo_small.png" style="vertical-align: middle;"/>\
    # <a href="#"><%= @assignment.title %></a>\
  # </h2>\
  # <div>\
    # <table style="width: auto;">\
      # <tr>\
        # <td style="padding: 2px 5px;">Due:</td>\
        # <td style="padding: 2px 5px;"><%= @assignment.due_at.strftime("%b %d by %I:%M%p") %></td>\
      # </tr><tr>\
        # <td style="padding: 2px 5px;">Graded:</td>\
        # <td style="padding: 2px 5px;">' + tally + ' <span style="font-size: 0.8em;">out of <%= @students.count %></span></td>\
      # </tr><tr>\
        # <td style="padding: 2px 5px;">Avg Score:</td>\
        # <td style="padding: 2px 5px;">' + averageScore + ' <span style="font-size: 0.8em;">out of 20</span></td>\
      # </tr><tr>\
        # <td colspan="2" style="text-align: right; padding: 2px 5px;">\
          # <a href="#" onclick="instructureEmbedToggleStudentScores(this); return false;">Show Student Scores</a>\
        # </td>\
      # </tr>\
    # </table>\
  # </div>\
  # <div style="overflow: auto; max-height: 200px; margin-left: 30px; display: none;" id="instructure_embedded_assignment_students">\
    # <table style="width: auto;">\
      # <thead>\
        # <tr>\
          # <th style="text-align: left;">Student</th>\
          # <th style="min-width: 100px;">Score</th>\
          # <th style="text-align: left;">Turned In</td>\
        # </tr>\
      # </thead>\
      # <tbody>\
        # <tr>\
# ');
# var score, turnedIn;
# <% @students.each do |student| %>
# score = "-";
# turnedIn = "-";
# if(submissionData['<%= student.id %>']) {
  # var data = submissionData['<%= student.id %>'];
  # score = data.grade;
  # if(score === null || score === "") {
    # score = "-";
  # } else {
    # turnedIn = data.created_at;
  # }
# }
# document.write('\
          # <td style="padding: 3px 10px 3px 0px;"><%= student.name %></td>\
          # <td style="padding: 3px 30px; text-align: center;">' + score + '</td>\
          # <td style="padding: 3px 10px; text-align: center;">' + turnedIn + '</td>\
        # </tr><tr>\
# ');
# <% end %>
# document.write('\
        # </tr>\
    # </table>\
  # </div>\
  # <div style="text-align: right; margin-top: 20px;">\
    # <a href="">Course Home</a> | \
    # <a href="<%= @gradebook_url %>">Gradebook</a> | \
    # <a href="#" onclick="instructureEmbedShowSettings(); return false;">Page Settings</a> | \
    # <a href="#" onclick="instructureEmbedShowStudentView(); return false;">Student View</a>\
  # </div>\
# </div>\
# ');
# <%= render :partial => "embed_settings_js" %>
# <%= render :partial => "student_assignment_js", :object => @students[0], :locals => { :example_student => true } %>
