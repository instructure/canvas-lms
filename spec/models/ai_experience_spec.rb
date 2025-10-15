# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe AiExperience do
  let(:account) { Account.create! }
  let(:root_account) { Account.default }
  let(:course) { course_factory(account: root_account) }

  let(:valid_attributes) do
    {
      title: "Test AI Experience",
      description: "A test AI experience",
      facts: "These are test facts",
      learning_objective: "Learn something useful",
      pedagogical_guidance: "A test pedagogical guidance",
      course:
    }
  end

  describe "validations" do
    it "requires title, learning_objective, and pedagogical_guidance" do
      experience = AiExperience.new(valid_attributes.except(:title, :learning_objective, :pedagogical_guidance))
      expect(experience).not_to be_valid
      expect(experience.errors[:title]).to include("can't be blank")
      expect(experience.errors[:learning_objective]).to include("can't be blank")
      expect(experience.errors[:pedagogical_guidance]).to include("can't be blank")
    end

    it "validates title length" do
      experience = AiExperience.new(valid_attributes.merge(title: "a" * 256))
      expect(experience).not_to be_valid
    end

    it "validates workflow_state inclusion" do
      experience = AiExperience.new(valid_attributes.merge(workflow_state: "invalid_state"))
      expect(experience).not_to be_valid
      expect(experience.errors[:workflow_state]).to include("is not included in the list")
    end

    it "allows facts to be blank" do
      experience = AiExperience.new(valid_attributes.except(:facts))
      expect(experience).to be_valid
    end
  end

  describe "scopes" do
    let!(:published_exp) { AiExperience.create!(valid_attributes.merge(title: "Published", workflow_state: "published")) }
    let!(:unpublished_exp) { AiExperience.create!(valid_attributes.merge(title: "Unpublished", workflow_state: "unpublished")) }

    it "scopes work correctly" do
      expect(AiExperience.published).to contain_exactly(published_exp)
      expect(AiExperience.unpublished).to contain_exactly(unpublished_exp)
      expect(AiExperience.active).to contain_exactly(published_exp, unpublished_exp)
    end
  end

  describe "workflow state management" do
    let(:experience) { AiExperience.create!(valid_attributes) }

    it "can be published and unpublished" do
      expect(experience.publish!).to be true
      expect(experience.reload).to be_published

      expect(experience.unpublish!).to be true
      expect(experience.reload).to be_unpublished
    end

    it "can be soft deleted" do
      expect(experience.delete).to be true
      expect(experience.reload).to be_deleted
      expect(experience.publish!).to be false # Cannot publish deleted
    end

    it "can be permanently deleted" do
      experience_id = experience.id
      experience.destroy
      expect(AiExperience.find_by(id: experience_id)).to be_nil
    end
  end
end
