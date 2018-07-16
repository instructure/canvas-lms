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

require_relative '../helpers/assignments_common'
require_relative '../helpers/discussions_common'
require_relative '../helpers/files_common'

describe "discussion assignments" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include FilesCommon
  include AssignmentsCommon

  before(:each) do
    @domain_root_account = Account.default
    course_with_teacher_logged_in
  end

  context "created with 'more options'" do
    it "should redirect to the discussion new page and maintain parameters", priority: "1", test_id: 209966 do
      ag = @course.assignment_groups.create!(:name => "Stuff")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { build_assignment_with_type("Discussion", :assignment_group_id => ag.id, :name => "More options created discussion", :points => '30', :more_options => true)}
      #check the content of the discussion page for our set point value and name and the URL to make sure were in /discussions
      expect(driver.current_url).to include("discussion_topics/new?assignment_group_id=#{ag.id}&due_at=null&points_possible=30&title=More+options+created+discussion")
      expect(f('#discussion-title')).to have_value "More options created discussion"
      expect(f('#discussion_topic_assignment_points_possible')).to have_value "30"
    end
  end

  context "edited from the index page" do
    it "should update discussion when updated", priority: "2", test_id: 209967 do
      assign = @course.assignments.create!(:name => "Discuss!", :points_possible => "5", :submission_types => "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      edit_assignment(assign.id, :name => 'Rediscuss!', :submit => true)
      expect(assign.reload.discussion_topic.title).to eq "Rediscuss!"
    end
  end

  context "edited with 'more options'" do
    it "should redirect to the discussion edit page and maintain parameters", priority: "2", test_id: 209968 do
      assign = @course.assignments.create!(:name => "Discuss!", :points_possible => "5", :submission_types => "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load{ edit_assignment(assign.id, :name => "Rediscuss!", :points => "10", :more_options => true) }
      expect(f('#discussion-title')).to have_value "Rediscuss!"
      expect(f('#discussion_topic_assignment_points_possible')).to have_value "10"
    end
  end

  context "created with html in title" do
    it "should not render html in flash notice", priority: "2", test_id: 132616 do
      discussion_title = '<s>broken</s>'
      topic = create_discussion(discussion_title, 'threaded')
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      wait_for_ajaximations
      f('.announcement_cog').click
      fln('Delete').click
      driver.switch_to.alert.accept
      assert_flash_notice_message("#{discussion_title} deleted successfully")
    end
  end

  context "insert content using RCE" do
    it "should insert file using rce in a discussion", priority: "1", test_id: 126674 do
      discussion_title = 'New Discussion'
      topic = create_discussion(discussion_title, 'threaded')
      file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}/edit"
      insert_file_from_rce(:discussion)
    end
  end

  context "created by different users" do
    it "should list identical authors after a user merge", priority: "2", test_id: 85899 do
      @student_a = User.create!(:name => 'Student A')
      @student_b = User.create!(:name => 'Student B')
      discussion_a = @course.discussion_topics.create!(user: @student_a, title: 'title a', message: 'from student a')
      discussion_b = @course.discussion_topics.create!(user: @student_b, title: 'title b', message: 'from student b')
      discussion_b.discussion_entries.create!(user: @student_a, message: 'reply from student a')
      discussion_a.discussion_entries.create!(user: @student_b, message: 'reply from student b')
      UserMerge.from(@student_a).into(@student_b)
      @student_a.reload
      @student_b.reload
      get "/courses/#{@course.id}/discussion_topics/#{discussion_a.id}"
      expect(f("div .entry-content a.author").text).to eq "Student B"
      get "/courses/#{@course.id}/discussion_topics/#{discussion_b.id}"
      expect(f("div .discussion_subentries a.author").text).to eq "Student B"
    end
  end
end
