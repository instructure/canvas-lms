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

# document.write('\
# <a name="instructure_embedded_gradebook"></a>\
# <div id="instructure_embedded_page_content" style="margin-top: 30px;">\
  # <h2 style="margin-bottom: 0;">\
    # <img src="http://localhost:3000/images/logo_small.png" style="vertical-align: middle;"/>\
    # Course Gradebook\
  # </h2>\
  # <iframe src=\"<%= url_for :action => 'show', :course_id => @context.id, :host => 'localhost:3000', :view => 'simple' %>\" style=\"width: 100%; height: 400px; border: 0;\" frameborder="0"></iframe>\
  # <div style="text-align: right;">\
    # <a href="">Course Home</a> | \
    # <a href="#" onclick="instructureEmbedShowSettings(); return false;">Page Settings</a> | \
    # <a href="#" onclick="instructureEmbedShowStudentView(); return false;">Student View</a>\
  # </div>\
# </div>\
# ');
# <%= render :partial => "embed_settings_js" %>
# <%= render :partial => "student_gradebook_js", :object => @student, :locals => { :example_student => true } %>