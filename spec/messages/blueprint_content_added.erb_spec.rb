# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'blueprint_content_added' do
  before :once do
    @master = course_model(:reusable => true)
    @minion = course_model(:reusable => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    sub = @template.add_child_course!(@minion)
    mm = @template.master_migrations.create!(:imports_completed_at => 1.day.ago, :workflow_state => 'completed', :comment => 'ohai')
    @cm = @minion.content_migrations.build
    @cm.migration_type = "master_course_import"
    @cm.migration_settings[:master_migration_id] = mm.id
    @cm.child_subscription_id = sub.id
    @cm.workflow_state = 'imported'
    @cm.save!
  end

  let(:asset) { @cm }
  let(:notification_name) { :blueprint_content_added }

  include_examples "a message"
end
