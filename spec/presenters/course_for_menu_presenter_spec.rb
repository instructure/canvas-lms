#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe CourseForMenuPresenter do
  let_once(:course) { course_model }
  let_once(:user) { user_model }
  let(:dashboard_card_tabs) { UsersController::DASHBOARD_CARD_TABS }

  let_once(:presenter) do
    CourseForMenuPresenter.new(course, user, nil, nil, {tabs: dashboard_card_tabs})
  end

  describe '#to_h' do
    it 'returns hash of info about course' do
      expect(presenter.to_h).to be_a Hash
    end

    it 'shouldnt include tab links to unenrolled users' do
      expect(presenter.to_h[:links]).to be_empty
    end

    it 'should show all the tab links to a teacher' do
      course.enroll_teacher(user).accept
      course.assignments.create!
      course.discussion_topics.create!
      course.announcements.create! title: 'hear ye!', message: 'wat'
      course.attachments.create! filename: 'blah', uploaded_data: StringIO.new('blah')

      expect(presenter.to_h[:links]).to match_array([
        a_hash_including({css_class: "announcements", icon: "icon-announcement", label: "Announcements"}),
        a_hash_including({css_class: "discussions", icon: "icon-discussion", label: "Discussions"}),
        a_hash_including({css_class: "assignments", icon: "icon-assignment", label: "Assignments"}),
        a_hash_including({css_class: "files", icon: "icon-folder", label: "Files"})
      ])
    end

    it 'should only show the tabs a student has access to to students' do
      course.enroll_student(user).accept
      course.assignments.create!
      course.attachments.create! filename: 'blah', uploaded_data: StringIO.new('blah')

      expect(presenter.to_h[:links]).to match_array([
        a_hash_including({css_class: "assignments", icon: "icon-assignment", label: "Assignments"}),
        a_hash_including({css_class: "files", icon: "icon-folder", label: "Files"})
      ])
    end

    it 'returns the course nickname if one is set' do
      user.course_nicknames[course.id] = 'nickname'
      user.save!
      cs_presenter = CourseForMenuPresenter.new(course, user)
      h = cs_presenter.to_h
      expect(h[:originalName]).to eq course.name
      expect(h[:shortName]).to eq 'nickname'
    end

    context 'Dashcard Reordering' do
      before(:each) do
        @account = Account.default
      end

      it 'returns a position if one is set' do
        user.dashboard_positions[course.asset_string] = 3
        user.save!
        cs_presenter = CourseForMenuPresenter.new(course, user, @account)
        h = cs_presenter.to_h
        expect(h[:position]).to eq 3
      end

      it 'returns nil when no position is set' do
        cs_presenter = CourseForMenuPresenter.new(course, user, @account)
        h = cs_presenter.to_h
        expect(h[:position]).to eq nil
      end
    end

  end

  describe '#role' do
    specs_require_sharding
    it "should retrieve the correct role for cross-shard enrollments" do
      @shard1.activate do
        account = Account.create
        @role = account.roles.create :name => "1337 Student"
        @role.base_role_type = 'StudentEnrollment'
        @role.save!

        @cs_course = account.courses.create!
        @cs_course.primary_enrollment_role_id = @role.local_id
      end
      cs_presenter = CourseForMenuPresenter.new(@cs_course)
      expect(cs_presenter.send(:role)).to eq @role
    end
  end
end
