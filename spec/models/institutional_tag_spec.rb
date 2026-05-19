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

    describe "tag limit per category" do
      it "allows up to 50 tags in a category" do
        50.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        expect(category.institutional_tags.active.count).to eq(50)
      end

      it "rejects the 51st tag in a category" do
        50.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        tag = InstitutionalTag.new(valid_params.merge(name: "Tag 51"))
        expect(tag).not_to be_valid
        expect(tag.errors[:category]).to be_present
      end

      it "does not count soft-deleted tags toward the limit" do
        50.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        category.institutional_tags.active.first.destroy
        tag = InstitutionalTag.new(valid_params.merge(name: "Replacement Tag"))
        expect(tag).to be_valid
      end

      it "allows updating an existing tag when the category is at the limit" do
        50.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        existing_tag = category.institutional_tags.active.last
        existing_tag.name = "Updated Name"
        expect(existing_tag).to be_valid
      end

      it "prevents restoring a deleted tag when the category is at the limit" do
        50.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        deleted_tag = category.institutional_tags.active.first
        deleted_tag.destroy
        InstitutionalTag.create!(valid_params.merge(name: "Replacement"))
        deleted_tag.workflow_state = "active"
        expect(deleted_tag).not_to be_valid
        expect(deleted_tag.errors[:category]).to be_present
      end

      it "respects the configurable limit from DynamicSettings" do
        allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
        allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(
          DynamicSettings::FallbackProxy.new({ "institutional_tags_per_category_limit" => "3" })
        )
        3.times do |i|
          InstitutionalTag.create!(valid_params.merge(name: "Tag #{i}"))
        end
        tag = InstitutionalTag.new(valid_params.merge(name: "Tag 4"))
        expect(tag).not_to be_valid
        expect(tag.errors[:category]).to be_present
      end
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

    it "raises FK error on hard-delete when associations exist" do
      tag = InstitutionalTag.create!(valid_params)
      InstitutionalTagAssociation.create!(institutional_tag: tag, context: user)
      expect { tag.destroy_permanently! }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "cascade-archives active associations on soft-delete" do
      tag = InstitutionalTag.create!(valid_params)
      assoc = InstitutionalTagAssociation.create!(institutional_tag: tag, context: user)
      tag.destroy
      expect(assoc.reload.workflow_state).to eq "deleted"
    end

    it "does not touch already-deleted associations on soft-delete" do
      tag = InstitutionalTag.create!(valid_params)
      assoc = InstitutionalTagAssociation.create!(institutional_tag: tag, context: user)
      assoc.destroy
      tag.destroy
      expect(assoc.reload.workflow_state).to eq "deleted"
    end

    it "cascade-archives associations when workflow_state is set directly" do
      tag = InstitutionalTag.create!(valid_params)
      assoc = InstitutionalTagAssociation.create!(institutional_tag: tag, context: user)
      tag.update!(workflow_state: "deleted")
      expect(assoc.reload.workflow_state).to eq "deleted"
    end
  end

  describe ".cascade_archive_associations_for" do
    it "bulk soft-deletes associations for given tag IDs" do
      tag1 = InstitutionalTag.create!(valid_params)
      tag2 = InstitutionalTag.create!(valid_params.merge(name: "Tag 2"))
      user2 = user_model
      assoc1 = InstitutionalTagAssociation.create!(institutional_tag: tag1, context: user)
      assoc2 = InstitutionalTagAssociation.create!(institutional_tag: tag2, context: user2)

      InstitutionalTag.cascade_archive_associations_for([tag1.id, tag2.id])

      expect(assoc1.reload.workflow_state).to eq "deleted"
      expect(assoc2.reload.workflow_state).to eq "deleted"
    end

    it "does not touch associations for other tags" do
      tag1 = InstitutionalTag.create!(valid_params)
      tag2 = InstitutionalTag.create!(valid_params.merge(name: "Tag 2"))
      assoc1 = InstitutionalTagAssociation.create!(institutional_tag: tag1, context: user)
      InstitutionalTagAssociation.create!(institutional_tag: tag2, context: user_model)

      InstitutionalTag.cascade_archive_associations_for([tag1.id])

      expect(assoc1.reload.workflow_state).to eq "deleted"
      expect(tag2.institutional_tag_associations.active.count).to eq 1
    end

    it "is a no-op for empty tag IDs" do
      expect { InstitutionalTag.cascade_archive_associations_for([]) }.not_to raise_error
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
