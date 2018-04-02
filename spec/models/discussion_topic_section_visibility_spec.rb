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
#

# require 'rails_helper'

require_relative '../sharding_spec_helper'
require_relative '../selenium/helpers/groups_common'
require_relative '../lti2_spec_helper'

describe DiscussionTopicSectionVisibility do
  before :once do
    @course1 = course_factory({ :course_name => "Course 1" })
    @course2 = course_factory({ :course_name => "Course 2" })
    course_with_teacher(active_all: true)
    @section1 = @course1.course_sections.create!
    @section2 = @course2.course_sections.create!
    @course1.save!
    @course2.save!
    @announcement = Announcement.create!(
      :title => "some topic",
      :message => "I announce that i am lying",
      :user => @teacher,
      :context => @course1,
      :workflow_state => "published"
    )
  end

  it 'forbid non-section-specific topics from having sections' do
    @announcement.is_section_specific = false
    @announcement.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        :discussion_topic => @announcement,
        :course_section => @section1
      )
    expect(@announcement.valid?).to eq false
    errors = @announcement.discussion_topic_section_visibilities.first.errors[:discussion_topic_id]
    expect(errors).to eq ["Cannot add section to a non-section-specific discussion"]
  end

  it 'forbid sections with wrong context' do
    @announcement.is_section_specific = true
    @announcement.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        :discussion_topic => @announcement,
        :course_section => @section2 # section in wrong course
      )
    expect(@announcement.valid?).to eq false
    errors = @announcement.discussion_topic_section_visibilities.first.errors[:course_section_id]
    expect(errors).to eq ["Section does not belong to course for this discussion topic"]
  end

  it 'valid entry' do
    @announcement.is_section_specific = true
    @announcement.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        :discussion_topic => @announcement,
        :course_section => @section1
      )
    expect(@announcement.valid?).to eq true
    expect(@announcement.discussion_topic_section_visibilities.length).to eq 1
    expect(@announcement.discussion_topic_section_visibilities.first.valid?).to eq true
  end

  def add_section_to_announcement(announcement, section)
    announcement.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        :discussion_topic => announcement,
        :course_section => section
      )
  end

  def basic_announcement_model(course)
    announcement = Announcement.create!(
      :title => "some topic",
      :message => "I announce that i am lying",
      :user => @teacher,
      :context => course,
      :workflow_state => "published",
    )
    announcement
  end

  it 'duplicates' do
    course3 = course_factory({ :course_name => "Course 3" })
    section3a = course3.course_sections.create!
    section3b = course3.course_sections.create!
    announcement1 = basic_announcement_model(course3)
    announcement1.is_section_specific = true
    add_section_to_announcement(announcement1, section3a)
    announcement1.save!
    announcement2 = basic_announcement_model(course3)
    announcement2.is_section_specific = true
    # Two *different* announcements can have the same section.
    add_section_to_announcement(announcement2, section3a)
    announcement2.save!
    expect(announcement2.discussion_topic_section_visibilities.first.valid?).to eq true
    bad_duplicate_visibility = DiscussionTopicSectionVisibility.new(
      :discussion_topic => announcement1,
      :course_section => section3a
    )
    expect(bad_duplicate_visibility.valid?).to eq false
    section3b_visibility = DiscussionTopicSectionVisibility.new(
      :discussion_topic => announcement1,
      :course_section => section3b
    )
    expect(section3b_visibility.valid?).to eq true
    section3b_visibility.save! # Should success because it's a different section
    # We needed to save the second section first because section specific topics
    # actually have to have sections
    DiscussionTopicSectionVisibility.where(:discussion_topic => announcement1,
      :course_section => section3a).first.destroy!
    # Now that we deleted the first section 3a visibility, we can add another one
    reborn_section3a_visibility = DiscussionTopicSectionVisibility.new(
      :discussion_topic => announcement1,
      :course_section => section3a
    )
    expect(reborn_section3a_visibility.valid?).to eq true
  end
end
