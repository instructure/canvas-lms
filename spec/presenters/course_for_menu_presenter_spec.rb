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
  let_once(:account) { Account.default }
  let_once(:course) { Course.create!(account: account) }
  let_once(:user) { User.create! }

  let(:dashboard_card_tabs) { UsersController::DASHBOARD_CARD_TABS }

  let_once(:presenter) do
    CourseForMenuPresenter.new(course, user, account, nil, {tabs: dashboard_card_tabs})
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
      user.set_preference(:course_nicknames, course.id, 'nickname')
      cs_presenter = CourseForMenuPresenter.new(course, user, account)
      h = cs_presenter.to_h
      expect(h[:originalName]).to eq course.name
      expect(h[:shortName]).to eq 'nickname'
    end

    it 'sets isFavorited to true if course is favorited and unfavorite_course_from_dashboard flag enabled' do
      user.account.enable_feature!(:unfavorite_course_from_dashboard)
      course.enroll_student(user)
      Favorite.create!(user: user, context: course)
      cs_presenter = CourseForMenuPresenter.new(course, user, account)
      h = cs_presenter.to_h
      expect(h[:isFavorited]).to eq true
    end

    it 'sets isFavorited to false if course is favorited and unfavorite_course_from-dashboard flag disabled' do
      course.enroll_student(user)
      Favorite.create!(user: user, context: course)
      cs_presenter = CourseForMenuPresenter.new(course, user, account)
      h = cs_presenter.to_h
      expect(h[:isFavorited]).to eq false
    end

    it 'sets isFavorited to false if course is unfavorited and unfavorite_course_from_dashboard flag enabled' do
      user.account.enable_feature!(:unfavorite_course_from_dashboard)
      course.enroll_student(user)
      cs_presenter = CourseForMenuPresenter.new(course, user, account)
      h = cs_presenter.to_h
      expect(h[:isFavorited]).to eq false
    end

    it 'sets isFavorited to false if course is unfavorited and unfavorite_course_from_dashboard flag disabled' do
      course.enroll_student(user)
      cs_presenter = CourseForMenuPresenter.new(course, user, account)
      h = cs_presenter.to_h
      expect(h[:isFavorited]).to eq false
    end

    context 'with the `unpublished_courses` FF enabled' do
      before(:each) do
        course.root_account.enable_feature!(:unpublished_courses)
      end

      it 'sets additional keys' do
        cs_presenter = CourseForMenuPresenter.new(course, user, account)
        h = cs_presenter.to_h
        expect(h.key?(:published)).to eq true
        expect(h.key?(:canChangeCourseState)).to eq true
        expect(h.key?(:defaultView)).to eq true
        expect(h.key?(:pagesUrl)).to eq true
        expect(h.key?(:frontPageTitle)).to eq true
      end
    end

    context 'Dashcard Reordering' do
      it 'returns a position if one is set' do
        user.set_dashboard_positions(course.asset_string => 3)
        cs_presenter = CourseForMenuPresenter.new(course, user, account)
        h = cs_presenter.to_h
        expect(h[:position]).to eq 3
      end

      it 'returns nil when no position is set' do
        cs_presenter = CourseForMenuPresenter.new(course, user, account)
        h = cs_presenter.to_h
        expect(h[:position]).to eq nil
      end
    end

    context 'Using courses from a trusted account' do
      it 'returns correct published value if the current account has FF enabled' do
        account.enable_feature!(:unpublished_courses)
        a2 = account_model(name: "second account")
        a2.trust_links.create!(managing_account: account)
        account.trust_links.create!(managing_account: a2)
        course2 = a2.courses.create!(name: "course02")

        cs_presenter = CourseForMenuPresenter.new(course2, user, account)
        h = cs_presenter.to_h
        expect(h.key?(:published)).to eq true
      end
    end
  end
end
