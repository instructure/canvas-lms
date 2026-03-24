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

describe InstitutionalTagAssociation do
  let(:account) { account_model }
  let(:user) { user_model }
  let(:tag) { institutional_tag_model(account:) }

  let(:valid_params) do
    {
      institutional_tag: tag,
      context: user,
    }
  end

  it_behaves_like "soft deletion" do
    subject { InstitutionalTagAssociation }

    let(:second_user) { user_model }
    let(:creation_arguments) do
      [
        valid_params,
        valid_params.merge(context: second_user),
      ]
    end
  end

  describe "validations" do
    it "requires an institutional_tag" do
      record = InstitutionalTagAssociation.new(valid_params.except(:institutional_tag))
      expect(record).not_to be_valid
    end

    it "requires a context" do
      record = InstitutionalTagAssociation.new(valid_params.except(:context))
      expect(record).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to an institutional_tag" do
      assoc = InstitutionalTagAssociation.create!(valid_params)
      expect(assoc.institutional_tag).to eq(tag)
    end

    it "supports user as context" do
      assoc = InstitutionalTagAssociation.create!(valid_params)
      expect(assoc.context).to eq(user)
    end

    it "supports course as context" do
      course = course_model(account:)
      assoc = InstitutionalTagAssociation.create!(valid_params.merge(context: course))
      expect(assoc.context).to eq(course)
    end
  end

  describe "User associations" do
    it "user has many institutional_tag_associations" do
      InstitutionalTagAssociation.create!(valid_params)
      expect(user.institutional_tag_associations).not_to be_empty
    end

    it "user has many institutional_tags through associations" do
      InstitutionalTagAssociation.create!(valid_params)
      expect(user.institutional_tags).to include(tag)
    end
  end

  describe "Course associations" do
    let(:course) { course_model(account:) }

    it "course has many institutional_tag_associations" do
      InstitutionalTagAssociation.create!(valid_params.merge(context: course))
      expect(course.institutional_tag_associations).not_to be_empty
    end

    it "course has many institutional_tags through associations" do
      InstitutionalTagAssociation.create!(valid_params.merge(context: course))
      expect(course.institutional_tags).to include(tag)
    end
  end

  describe "root_account_id" do
    it "resolves root_account from the institutional_tag" do
      root_account = account_model
      sub_account = account_model(parent_account: root_account)
      tag = institutional_tag_model(account: sub_account)
      assoc = InstitutionalTagAssociation.create!(valid_params.merge(institutional_tag: tag))
      expect(assoc.root_account_id).to eq(root_account.id)
    end
  end
end
