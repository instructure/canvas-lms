#
# Copyright (C) 2013 - 2016 Instructure, Inc.
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

require_relative 'report_spec_helper'

describe 'lti report' do
  include ReportSpecHelper

  before(:once) do
    @type = 'lti_report_csv'
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @sub_account = Account.create(parent_account: @account, name: 'Sub Account')
    @sub_account2 = Account.create(parent_account: @account, name: 'Sister Sub Account')
    @course2 = Course.create(name: 'New Course', account: @sub_account2)
    @course = Course.create(name: 'New Course', account: @sub_account)

    @t1 = ContextExternalTool.new.tap do |t|
      t.context_id = @account.id
      t.context_type = 'Account'
      t.name = 'Account Tool'
      t.consumer_key = 'key'
      t.shared_secret = 'secret'
      t.tool_id = 'Vimeo'
      t.url = 'https://launch_url.test'
      t.save
    end

    @t2 = ContextExternalTool.new.tap do |t|
      t.context_id = @course.id
      t.context_type = 'Course'
      t.name = 'Course Tool'
      t.consumer_key = 'key'
      t.shared_secret = 'secret'
      t.tool_id = 'Youtube'
      t.url = 'https://launch_url.test'
      t.save
    end

    @t3 = ContextExternalTool.new.tap do |t|
      t.context_id = @course2.id
      t.context_type = 'Course'
      t.name = 'Course Tool2'
      t.consumer_key = 'key'
      t.shared_secret = 'secret'
      t.tool_id = 'Youtube'
      t.url = 'https://launch_url.test'
      t.save
    end
  end

  it 'should run on a root account' do
    parsed = read_report(@type, {order: 4})
    expect(parsed.length).to eq 3
    expect(parsed[0]).to eq([
      @t1.context_type,
      @t1.context_id.to_s,
      @account.name,
      nil,
      @t1.name,
      @t1.tool_id,
      @t1.created_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
      @t1.privacy_level,
      @t1.url,
      nil
    ])
  end

  it 'should run on a sub account' do
    parsed = read_report(@type, {order: 4, account: @sub_account})
    expect(parsed.length).to eq 1
    expect(parsed[0]).to eq([
      @t2.context_type,
      @t2.context_id.to_s,
      nil,
      @course.name,
      @t2.name,
      @t2.tool_id,
      @t2.created_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
      @t2.privacy_level,
      @t2.url,
      nil
    ])
  end

  it 'should not include tools from deleted courses' do
    @course.destroy
    parsed = read_report(@type, {order: 4})
    expect(parsed.length).to eq 2
  end

  it 'should not include tools from courses in deleted accounts' do
    @sub_account2.destroy
    parsed = read_report(@type, {order: 4})
    expect(parsed.length).to eq 2
  end
end
