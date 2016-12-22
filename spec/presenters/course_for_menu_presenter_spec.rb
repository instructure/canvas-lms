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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe CourseForMenuPresenter do
  let_once(:course) { course_model }
  let_once(:available_section_tabs) do
    Course.default_tabs.select do |tab|
      [ Course::TAB_ASSIGNMENTS, Course::TAB_HOME ].include?(tab[:id])
    end
  end
  let_once(:presenter) do
    CourseForMenuPresenter.new(
      course, available_section_tabs
    )
  end

  describe '#initialize' do
    it 'should limit available_section_tabs to be those for dashboard' do
      available_section_tab_ids = presenter.available_section_tabs.map do |tab|
        tab[:id]
      end
      expect(available_section_tab_ids).to include(Course::TAB_ASSIGNMENTS)
      expect(available_section_tab_ids).not_to include(Course::TAB_HOME)
    end
  end

  describe '#to_h' do
    it 'returns hash of info about course' do
      expect(presenter.to_h).to be_a Hash
    end

    it 'should include available_section_tabs as link element of hash' do
      expect(presenter.to_h[:links].length).to eq presenter.available_section_tabs.length
    end

    it 'returns the course nickname if one is set' do
      user = user_model
      user.course_nicknames[course.id] = 'nickname'
      user.save!
      cs_presenter = CourseForMenuPresenter.new(course, nil, user)
      h = cs_presenter.to_h
      expect(h[:originalName]).to eq course.name
      expect(h[:shortName]).to eq 'nickname'
    end

    context 'with Dashcard Reordering feature enabled' do
      before(:each) do
        @account = Account.default
        @account.enable_feature! :dashcard_reordering
      end

      it 'returns a position if one is set' do
        user = user_model
        user.dashboard_positions[course.asset_string] = 3
        user.save!
        cs_presenter = CourseForMenuPresenter.new(course, nil, user, @account)
        h = cs_presenter.to_h
        expect(h[:position]).to eq 3
      end

      it 'returns nil when no position is set' do
        user = user_model
        cs_presenter = CourseForMenuPresenter.new(course, nil, user, @account)
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
      cs_presenter = CourseForMenuPresenter.new(@cs_course, available_section_tabs)
      expect(cs_presenter.send(:role)).to eq @role
    end
  end
end
