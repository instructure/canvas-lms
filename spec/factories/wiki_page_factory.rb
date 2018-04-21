#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def wiki_page_model(opts={})
    course = opts.delete(:course) || (course_with_student(active_all: true); @course)
    opts = opts.slice(:title, :body, :url, :user_id, :user, :editing_roles, :notify_of_update, :todo_date)
    @page = course.wiki_pages.create!(valid_wiki_page_attributes.merge(opts))
  end

  def wiki_page_assignment_model(opts={})
    @page = opts.delete(:wiki_page) || wiki_page_model(opts)
    assignment_model({
      course: @page.course,
      wiki_page: @page,
      submission_types: 'wiki_page',
      title: 'Content Page Assignment',
      due_at: nil
    }.merge(opts))
  end

  def valid_wiki_page_attributes
    {
      title: "some page"
    }
  end
end
