# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe InstitutionalTagCategory do
  let(:account) { account_model }
  let(:valid_params) { { name: "Category", account: } }

  it_behaves_like "soft deletion" do
    subject { InstitutionalTagCategory }

    let(:creation_arguments) do
      [
        valid_params.merge(name: "Category A"),
        valid_params.merge(name: "Category B"),
      ]
    end
  end

  describe "validations" do
    it "requires a name" do
      record = InstitutionalTagCategory.new(valid_params.except(:name))
      expect(record).not_to be_valid
      expect(record.errors[:name]).to be_present
    end

    it "requires name to be at most 255 characters" do
      record = InstitutionalTagCategory.new(valid_params.merge(name: "a" * 256))
      expect(record).not_to be_valid
    end

    it "requires an account" do
      record = InstitutionalTagCategory.new(valid_params.except(:account))
      expect(record).not_to be_valid
    end

    it "enforces unique name per root_account among active records (case-insensitive)" do
      InstitutionalTagCategory.create!(valid_params)
      expect do
        InstitutionalTagCategory.create!(valid_params.merge(name: valid_params[:name].upcase))
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows duplicate name if existing record is deleted" do
      first = InstitutionalTagCategory.create!(valid_params)
      first.destroy
      duplicate = InstitutionalTagCategory.new(valid_params)
      expect(duplicate).to be_valid
    end
  end

  describe "associations" do
    it "has many institutional_tags" do
      category = InstitutionalTagCategory.create!(valid_params)
      tag = InstitutionalTag.create!(
        name: "Tag",
        description: "desc",
        category:
      )
      expect(category.institutional_tags).to include(tag)
    end

    it "restricts deletion when tags exist" do
      category = InstitutionalTagCategory.create!(valid_params)
      InstitutionalTag.create!(
        name: "Tag",
        description: "desc",
        category:
      )
      expect { category.destroy_permanently! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end

  describe "Account associations" do
    it "account has many institutional_tag_categories" do
      InstitutionalTagCategory.create!(valid_params)
      expect(account.institutional_tag_categories).not_to be_empty
    end
  end

  describe "root_account_id" do
    it "resolves root_account from account" do
      root_account = account_model
      sub_account = account_model(parent_account: root_account)
      category = InstitutionalTagCategory.create!(valid_params.merge(account: sub_account))
      expect(category.root_account_id).to eq(root_account.id)
    end
  end
end
