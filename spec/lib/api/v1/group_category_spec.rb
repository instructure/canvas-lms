#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative '../../../spec_helper'

class CategoryHarness
  include Api::V1::GroupCategory

  def polymorphic_url(data)
    "http://www.example.com/api/#{data.join('/')}"
  end
end

describe "Api::V1::GroupCategory" do
  describe "#group_category_json" do
    let(:category){ GroupCategory.new(name: "mygroup", root_account: Account.new) }

    it "includes the auto_leader value" do
      category.auto_leader = 'random'
      json = CategoryHarness.new.group_category_json(category, nil, nil)
      expect(json['auto_leader']).to eq('random')
    end

    describe 'groups_count' do
      it 'is absent without the includes' do
        json = CategoryHarness.new.group_category_json(category, nil, nil, {})
        expect(json.keys.include?("groups_count")).to be(false)
      end

      it 'is present with the includes' do
        allow(category).to receive_messages(:groups => double(active: double(size: 3)), :is_member? => false)
        json = CategoryHarness.new.group_category_json(category, nil, nil, {:include => ['groups_count']})
        expect(json["groups_count"]).to eq(3)
      end
    end

    describe 'progress_url' do
      it 'is absent without the includes' do
        json = CategoryHarness.new.group_category_json(category, nil, nil, {})
        expect(json.keys.include?("progress")).to be(false)
      end

      it 'is present with the includes' do
        allow(category).to receive_messages(current_progress: double(:pending? => true))
        json = CategoryHarness.new.group_category_json(category, nil, nil, {:include => ['progress_url']})
        expect(json["progress"]['url']).to match(/example.com\/api\/api_v1/)
      end
    end

    describe 'group_category_data' do
      it 'sets protected with the category value' do
        allow(category).to receive_messages(:protected? => true)
        json = CategoryHarness.new.group_category_json(category, nil, nil)
        expect(json["protected"]).to eq(true)
      end

      it 'passes through "allows_multiple_memberships"' do
        allow(category).to receive_messages(:allows_multiple_memberships? => false)
        json = CategoryHarness.new.group_category_json(category, nil, nil)
        expect(json["allows_multiple_memberships"]).to eq(false)
      end

      it 'checks the user against the category to set "is_member"' do
        user = User.new
        expect(category).to receive(:is_member?).with(user).and_return(true)
        json = CategoryHarness.new.group_category_json(category, user, nil)
        expect(json["is_member"]).to eq(true)
      end
    end

  end
end
