#
# Copyright (C) 2012 Instructure, Inc.
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

describe "course" do

  # normally this would be a controller test, but there is a some code in the
  # views that i need to not explode
  it "should not require authorization for public courses" do
    course(:active_all => true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}"
    expect(response).to be_success
  end

  it "should load syllabus on public course with no user logged in" do
    course(:active_all => true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}/assignments/syllabus"
    expect(response).to be_success
  end

  it "should show the migration-in-progress notice" do
    enable_cache do
      course(active_all: true)
      user_session(@teacher)
      migration = @course.content_migrations.build
      migration.migration_settings[:import_in_progress_notice] = '1'
      migration.save!

      migration.update_attribute(:workflow_state, 'importing')
      get "/courses/#{@course.id}"
      expect(response).to be_success
      body = Nokogiri::HTML(response.body)
      expect(body.css('div.import-in-progress-notice')).not_to be_empty

      migration.update_attribute(:workflow_state, 'imported')
      get "/courses/#{@course.id}"
      expect(response).to be_success
      body = Nokogiri::HTML(response.body)
      expect(body.css('div.import-in-progress-notice')).to be_empty
    end
  end

  it "should not show the migration-in-progress notice to students" do
    enable_cache do
      course(active_all: true)
      student_in_course active_all: true
      user_session(@student)
      migration = @course.content_migrations.build
      migration.migration_settings[:import_in_progress_notice] = '1'
      migration.save!

      migration.update_attribute(:workflow_state, 'importing')
      get "/courses/#{@course.id}"
      expect(response).to be_success
      body = Nokogiri::HTML(response.body)
      expect(body.css('div.import-in-progress-notice')).to be_empty
    end
  end
end
