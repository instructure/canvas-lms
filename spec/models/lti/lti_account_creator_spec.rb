#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiAccountCreator do
  let(:root_account) do
    Account.create!.tap do |account|
      account.name = 'root_account'
      account.lti_guid = 'lti_guid'
      account.stubs(:domain).returns('account_domain')
      account.stubs(:id).returns(42)
      account.sis_source_id = 'account_sis_id'
    end
  end
  let(:canvas_tool) do
    ContextExternalTool.new.tap do |canvas_tool|
      canvas_tool.context = root_account
      canvas_tool.stubs(:opaque_identifier_for).returns('opaque_id')
    end
  end
  let(:canvas_user) { user(name: 'Shorty McLongishname') }
  let(:canvas_account) do
    Account.create!.tap do |account|
      account.name = 'account_name'
      account.root_account = root_account
      account.stubs(:id).returns(123)
      account.sis_source_id = 'sis_id'
    end
  end
  let(:canvas_course) do
    course(active_course: true, course_name: 'my course').tap do |course|
      course.course_code = 'abc'
      course.sis_source_id = 'sis_id'
      course.root_account = root_account
      course.account = canvas_account
      course.stubs(:id).returns(123)
    end
  end

  describe "#convert" do
    it 'creates an account for a Canvas Account' do
      account = Lti::LtiAccountCreator.new(canvas_account, canvas_tool).convert
      expect(account.id).to eq 123
      expect(account.name).to eq 'account_name'
      expect(account.sis_source_id).to eq 'sis_id'
    end

    it 'creates an account for a Canvas Course' do
      account = Lti::LtiAccountCreator.new(canvas_course, canvas_tool).convert
      expect(account.id).to eq 123
      expect(account.name).to eq 'account_name'
      expect(account.sis_source_id).to eq 'sis_id'
    end

    it 'creates an account for a Canvas User' do
      account = Lti::LtiAccountCreator.new(canvas_user, canvas_tool).convert
      expect(account.id).to eq 42
      expect(account.name).to eq 'root_account'
      expect(account.sis_source_id).to eq 'account_sis_id'
    end
  end
end
