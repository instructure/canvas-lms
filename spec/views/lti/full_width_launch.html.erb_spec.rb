# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')


describe "lti full width launch view" do

  include_context "lti_layout_spec_helper"

  let(:user) { User.create! }
  let(:enrollment) { tool.course.enroll_student(user) }

  before :each do
    ctrl.instance_variable_set(:@current_user, user)
    ctrl.instance_variable_set(:@domain_root_account, Account.default)
  end

  context "with an expired course" do
    before :each do
      enrollment.enrollment_state.state = "completed"
      enrollment.save!
    end

    it "should warn about a quiz in an expired course" do
      pending("wait for INTEROP-6784 to be merged")
      ctrl.send(:content_tag_redirect, Account.default, tag, nil)
      expect(ctrl.response.body).to have_text('no longer available')
    end
  end

  context "with an active course" do
    it "should not warn about the quiz being unavailable" do
      ctrl.send(:content_tag_redirect, Account.default, tag, nil)
      expect(ctrl.response.body).not_to have_text('no longer available')
    end
  end

end
