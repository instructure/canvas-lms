#
# Copyright (C) 2015 Instructure, Inc.
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
#
require_relative "../../spec_helper.rb"

describe WikiPages::ScopedToUser do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "some user")
  end
  let_once(:published) do
    @course.wiki.wiki_pages.create({
      title: 'published page',
      workflow_state: 'published'
    })
  end

  let_once(:unpublished) do
    @course.wiki.wiki_pages.create({
      title: 'unpublished page'
    }).tap do |page|
      page.unpublish
    end
  end

  describe '#scope' do

    it 'should return all pages if user can :view_unpublished_items' do
      expect(@course.grants_right?(@teacher, :view_unpublished_items)).to be_truthy, 'precondition'
      expect(unpublished.workflow_state).to eq('unpublished'), 'precondition'
      expect(published.workflow_state).to eq('active'), 'precondition'
      scope = @course.wiki.wiki_pages.select(WikiPage.column_names - ['body']).includes(:user)
      scope_filter = WikiPages::ScopedToUser.new(@course, @teacher, scope)
      expect(scope_filter.scope).to include(unpublished, published)
    end

    it 'should return only published pages if user cannot :view_unpublished_items' do
      expect(@course.grants_right?(@student, :view_unpublished_items)).to be_falsey, 'precondition'
      expect(unpublished.workflow_state).to eq('unpublished'), 'precondition'
      expect(published.workflow_state).to eq('active'), 'precondition'
      scope = @course.wiki.wiki_pages.select(WikiPage.column_names - ['body']).includes(:user)
      scope_filter = WikiPages::ScopedToUser.new(@course, @student, scope)
      expect(scope_filter.scope).not_to include(unpublished)
      expect(scope_filter.scope).to include(published)
    end

  end
end