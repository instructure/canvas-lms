#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'

describe "master courses - child courses - discussion locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    due_date = format_date_for_view(Time.zone.now + 1.month)
    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_topic = @copy_from.discussion_topics.create!(
      :title => "blah", :message => "bloo"
    )
    @tag = @template.create_content_tag_for!(@original_topic)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    # just create a copy directly instead of doing a real migration
    @topic_copy = @copy_to.discussion_topics.new(
      :title => "blah", :message => "bloo"
    )
    @topic_copy.migration_id = @tag.migration_id
    @topic_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the deletion cog-menu option on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@copy_to.id}/discussion_topics"

    expect(f('.discussion-row')).to contain_css('.icon-blueprint-lock')

    f('.discussion-row .al-trigger').click
    expect(f('.discussion-row')).not_to include_text('Delete')
  end

  it "should show all the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/discussion_topics"

    expect(f('.discussion-row')).to contain_css('.icon-blueprint')

    f('.discussion-row .al-trigger').click
    expect(f('.discussion-row')).to include_text('Delete')
  end

  it "should not show the delete options on the show page when locked" do
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

    expect(f('#content')).to contain_css('.edit-btn')
    f('.al-trigger').click
    expect(f('.al-options')).not_to contain_css('.delete_discussion')
  end

  it "should show the delete cog-menu options on the show when not locked" do
    get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

    f('.al-trigger').click
    expect(f('.al-options')).to contain_css('.delete_discussion')
  end

  it "should not allow popup editing of restricted items" do
    # restrict everything
    @tag.update_attribute(:restrictions, {:content => true, :points => true, :due_dates => true, :availability_dates => true})

    get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}/edit"

    expect(f("#discussion-title").tag_name).to eq "h1"
    expect(f("#discussion-description").tag_name).to eq "div"
    # this passes because the UI elems are on the page but hidden because the discussion is not graded
    expect(f("#discussion_topic_assignment_points_possible").attribute("readonly")).to eq "true"
    expect(f("#due_at").attribute("readonly")).to eq "true"
  end
end
