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

describe InstitutionalTag do
  let(:account) { account_model }
  let(:user) { user_model }
  let(:category) { institutional_tag_category_model(account:) }
  let(:valid_params) do
    {
      name: "Tag",
      description: "A tag description",
      category:,
    }
  end

  it_behaves_like "soft deletion" do
    subject { InstitutionalTag }

    let(:creation_arguments) do
      [
        valid_params.merge(name: "Tag A"),
        valid_params.merge(name: "Tag B"),
      ]
    end
  end

  describe "validations" do
    it "requires a name" do
      record = InstitutionalTag.new(valid_params.except(:name))
      expect(record).not_to be_valid
      expect(record.errors[:name]).to be_present
    end

    it "requires name to be at most 255 characters" do
      record = InstitutionalTag.new(valid_params.merge(name: "a" * 256))
      expect(record).not_to be_valid
    end

    it "requires a description" do
      record = InstitutionalTag.new(valid_params.except(:description))
      expect(record).not_to be_valid
      expect(record.errors[:description]).to be_present
    end

    it "requires a category" do
      record = InstitutionalTag.new(valid_params.except(:category))
      expect(record).not_to be_valid
    end

    it "enforces unique name per root_account among active records (case-insensitive)" do
      InstitutionalTag.create!(valid_params)
      expect do
        InstitutionalTag.create!(valid_params.merge(name: valid_params[:name].upcase))
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows duplicate name if existing record is deleted" do
      first = InstitutionalTag.create!(valid_params)
      first.destroy
      duplicate = InstitutionalTag.new(valid_params)
      expect(duplicate).to be_valid
    end

    it "enforces unique sis_source_id per root_account (case-insensitive)" do
      InstitutionalTag.create!(valid_params.merge(sis_source_id: "SIS1"))
      expect do
        InstitutionalTag.create!(valid_params.merge(name: "Other", sis_source_id: "SIS1"))
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows nil sis_source_id on multiple records" do
      InstitutionalTag.create!(valid_params.merge(sis_source_id: nil))
      second = InstitutionalTag.new(valid_params.merge(name: "Tag 2", sis_source_id: nil))
      expect(second).to be_valid
    end

    it "validates sis_source_id length" do
      record = InstitutionalTag.new(valid_params.merge(sis_source_id: "a" * 256))
      expect(record).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a category" do
      tag = InstitutionalTag.create!(valid_params)
      expect(tag.category).to eq(category)
    end

    it "has many institutional_tag_associations" do
      tag = InstitutionalTag.create!(valid_params)
      assoc = InstitutionalTagAssociation.create!(
        institutional_tag: tag,
        context: user
      )
      expect(tag.institutional_tag_associations).to include(assoc)
    end

    it "restricts deletion when associations exist" do
      tag = InstitutionalTag.create!(valid_params)
      InstitutionalTagAssociation.create!(
        institutional_tag: tag,
        context: user
      )
      expect { tag.destroy_permanently! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end

  describe "root_account_id" do
    it "resolves root_account from category" do
      root_account = account_model
      sub_account = account_model(parent_account: root_account)
      cat = institutional_tag_category_model(account: sub_account)
      tag = InstitutionalTag.create!(valid_params.merge(category: cat))
      expect(tag.root_account_id).to eq(root_account.id)
    end
  end
end
