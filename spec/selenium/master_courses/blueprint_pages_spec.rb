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


require_relative '../helpers/blueprint_common'

describe "master courses banner" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    @minion.enroll_teacher(@master_teacher).accept!

    # sets up the page that gets blueprinted
    @original_page = @master.wiki_pages.create! title: 'Unicorn', body: 'don\'t exist! Sorry James'
    run_master_course_migration(@master)
    @copy_page = @minion.wiki_pages.last
  end

  describe "as a master course teacher" do
    before :each do
      user_session(@master_teacher)
    end

    it "can lock down associated course's page content", priority: "1", test_id: 3127591 do
      change_blueprint_settings(@master, content: true)
      get "/courses/#{@master.id}/pages/#{@original_page.id}"
      f('.bpc-lock-toggle button').click
      expect { f('.bpc-lock-toggle__label').text }.to become('Locked')
      run_master_course_migration(@master)
      get "/courses/#{@minion.id}/pages/#{@copy_page.id}/edit"
      expect(f('#content-wrapper')).not_to contain_css('#tinymce')
    end

  end
end
