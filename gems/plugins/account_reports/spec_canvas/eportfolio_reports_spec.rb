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

require_relative 'report_spec_helper'

describe 'Eportfolio Reports' do
  include ReportSpecHelper

  before(:once) do
    @type = 'eportfolio_report_csv'
    @account1 = Account.default
    @account2 = Account.create(name: 'Root Account 2')
    @sub_account = Account.create(parent_account: @account1, name: 'Sub Account')
    user_with_pseudonym1 = user_with_pseudonym(account: @account2, active_user: true)
    user_with_pseudonym2 = user_with_pseudonym(active_user: true)
    user_with_enrollment = course_with_student(active_all: true).user
    pseudonym(user_with_enrollment, account: @account1)
    @eportfolio = Eportfolio.create!(user: user_with_pseudonym2, name: 'some spammy title')
    Eportfolio.create!(user: user_with_enrollment, name: 'My ePortfolio')
    Eportfolio.create!(user: user_with_pseudonym1, name: 'Root Account 2 ePortfolio')
  end

  it 'should be scoped to proper root account' do
    parsed = read_report(@type, { order: 1, account: @account2 })
    expect(parsed.length).to eq 1
  end

  it 'should run on a sub account' do
    parsed = read_report(@type, { order: 2, account: @sub_account })
    expect(parsed.length).to eq 2
  end

  it 'should default to reporting all active eportfolios for specified root account' do
    parsed = read_report(@type, { order: 2, account: @account1 })
    expect(parsed.length).to eq 2
  end

  it 'should only include deleted eportfolios' do
    @eportfolio.destroy
    parsed =
      read_report(@type, { params: { 'include_deleted' => true }, order: 1, account: @account1 })
    expect(parsed.length).to eq 1
  end

  it 'should only include eportfolios from users with no enrollments' do
    parsed =
      read_report(@type, { params: { 'no_enrollments' => true }, order: 1, account: @account1 })
    expect(parsed.length).to eq 1
  end

  it 'should only include deleted eportfolios from users with no enrollments' do
    @eportfolio.destroy
    parsed =
      read_report(
        @type,
        {
          params: { 'include_deleted' => true, 'no_enrollments' => true },
          order: 1,
          account: @account1
        }
      )
    expect(parsed.length).to eq 1
  end
end
