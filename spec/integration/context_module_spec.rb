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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContextModule do
  def course_module
    course_with_student_logged_in
    @module = @course.context_modules.create!(:name => "some module")
  end

  describe "must_contribute" do
    before do
      course_module
      @module.require_sequential_progress = true
      @module.save!
    end

    def before_after
      @module.completion_requirements = { @tag.id => { :type => 'must_contribute' } }
      @module.save!

      @progression = @module.evaluate_for(@user, true, true)
      @progression.should_not be_nil
      @progression.should_not be_completed
      @progression.should be_unlocked
      @progression.current_position.should eql(@tag.position)
      yield
      @progression = @module.evaluate_for(@user, true, true)
      @progression.should be_completed
      @progression.current_position.should eql(@tag.position)
    end

    it "should progress for discussions" do
      @discussion = @course.discussion_topics.create!(:title => "talk")
      @tag = @module.add_item(:type => 'discussion_topic', :id => @discussion.id)
      before_after do
        post "/courses/#{@course.id}/discussion_entries", :discussion_entry => { :message => 'ohai', :discussion_topic_id => @discussion.id }
        response.should be_redirect
      end
    end

    it "should progress for wiki pages" do
      @page = @course.wiki.wiki_pages.create!(:title => "talk page", :body => 'ohai', :editing_roles => 'teachers,students')
      @tag = @module.add_item(:type => 'wiki_page', :id => @page.id)
      before_after do
        put "/courses/#{@course.id}/wiki/#{@page.url}", :wiki_page => { :body => 'i agree', :title => 'talk page' }
        response.should be_redirect
      end
    end

    it "should progress for assignment discussions" do
      @assignment = @course.assignments.create(:title => 'talk assn', :submission_types => 'discussion_topic')
      @tag = @module.add_item(:type => 'assignment', :id => @assignment.id)
      before_after do
        post "/courses/#{@course.id}/discussion_entries", :discussion_entry => { :message => 'ohai', :discussion_topic_id => @assignment.discussion_topic.id }
        response.should be_redirect
      end
    end
  end
end
