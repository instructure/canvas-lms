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
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'alert' do
  before do
    course_with_student
    @alert = @course.alerts.create!(:recipients => [:student], :criteria => [:criterion_type => 'Interaction', :threshold => 7])
  end

  it "should render email" do
    generate_message(:alert, :email, @alert, :asset_context => @course.enrollments.first)
  end

  it "should render sms" do
    generate_message(:alert, :sms, @alert, :asset_context => @course.enrollments.first)
  end

  it "should render summary" do
    generate_message(:alert, :summary, @alert, :asset_context => @course.enrollments.first)
  end

  it "should render twitter" do
    generate_message(:alert, :twitter, @alert, :asset_context => @course.enrollments.first)
    expect(@message.main_link).to be_present
    expect(@message.body).to be_present
  end

  it "should render push" do
    generate_message(:alert, :push, @alert, asset_context: @course.enrollments.first)
  end
end
