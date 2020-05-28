#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe GoogleAnalyticsDimensions do
  subject do
    ->(account: Account.default, real_user: nil, user: nil) do
      described_class.calculate(
        domain_root_account: account,
        real_user: real_user,
        user: user
      )
    end
  end

  it 'tells when someone is a student' do
    dims = subject[user: student_in_course(active_all: true).user]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('100')
  end

  it 'tells when someone is a teacher' do
    dims = subject[user: teacher_in_course(active_all: true).user]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('010')
  end

  it 'tells when someone is an observer' do
    dims = subject[user: observer_in_course(active_all: true).user]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('001')
  end

  it 'tells when someone is both a teacher and an observer' do
    dims = subject[
      user: teacher_in_course(active_all: true).user.tap do |user|
        observer_in_course(user: user)
      end
    ]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('011')
  end

  it "it tells when someone is superman (or woman, lest i get fired)" do
    dims = subject[
      user: teacher_in_course(active_all: true).user.tap do |user|
        student_in_course(user: user, active_all: true)
        observer_in_course(user: user, active_all: true)
      end
    ]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('111')
  end

  it 'yields an empty set of enrollments for an anonymous session' do
    dims = subject[]

    expect(dims).to have_key(:enrollments)
    expect(dims[:enrollments]).to eq('000')
  end

  it "tells when someone is an admin" do
    dims = subject[user: account_admin_user]

    expect(dims).to have_key(:admin)
    expect(dims[:admin]).to eq '11'
  end

  it 'tells when someone is masquerading' do
    dims = subject[
      real_user: account_admin_user,
      user: student_in_course(active_all: true).user
    ]

    expect(dims).to have_key(:masquerading)
    expect(dims[:masquerading]).to eq '1'
  end

  it 'tells when someone is not masquerading' do
    user = user_with_pseudonym(active_all: true)
    dims = subject[real_user: user, user: user]

    expect(dims).to have_key(:masquerading)
    expect(dims[:masquerading]).to eq '0'
  end

  it 'reports the org type as found in Salesforce' do
    Account.default.external_integration_keys.create!(
      key_type: 'salesforce_org_type',
      key_value: 'K12'
    )

    expect(subject[][:org_type]).to eq 'K12'
  end

  describe 'identification' do
    it 'provides a consistent, predictable user identifier' do
      user = user_with_pseudonym(active_all: true)
      dims = subject[user: user]
      dims_again = subject[user: user]

      expect(dims).to have_key(:user_id)
      expect(dims_again).to have_key(:user_id)
      expect(dims[:user_id]).to eq(dims_again[:user_id])
    end

    it 'provides an identifier that is unique for the user' do
      emperor_tamarin = user_with_pseudonym(active_all: true)
      maryjane = user_with_pseudonym(active_all: true)

      expect(
        subject[user: emperor_tamarin][:user_id]
      ).not_to eq(
        subject[user: maryjane][:user_id]
      )
    end

    it 'provides an identifier that is NOT the canvas ID' do
      user = user_with_pseudonym(active_all: true)
      dims = subject[user: user]

      expect(dims[:user_id]).to be_present
      expect(dims[:user_id]).not_to eq(user.id)
    end
  end
end
