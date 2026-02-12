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

describe AiExperienceContextFile do
  let(:root_account) { Account.default }
  let(:course) { course_factory(account: root_account) }
  let(:ai_experience) do
    AiExperience.create!(
      title: "Test Experience",
      description: "Test description",
      facts: "Test facts",
      learning_objective: "Test objective",
      pedagogical_guidance: "Test guidance",
      course:
    )
  end
  let(:attachment) { attachment_model(context: course, size: 1.megabyte) }

  describe "validations" do
    it "validates uniqueness of attachment per ai_experience" do
      AiExperienceContextFile.create!(ai_experience:, attachment:)
      duplicate = AiExperienceContextFile.new(ai_experience:, attachment:)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:attachment_id]).to be_present
    end

    it "accepts files under 300MB" do
      small_attachment = attachment_model(context: course, size: 299.megabytes)
      context_file = AiExperienceContextFile.new(ai_experience:, attachment: small_attachment)
      expect(context_file).to be_valid
    end

    it "rejects files over 300MB" do
      large_attachment = attachment_model(context: course, size: 301.megabytes)
      context_file = AiExperienceContextFile.new(ai_experience:, attachment: large_attachment)
      expect(context_file).not_to be_valid
      expect(context_file.errors[:attachment]).to include("file size must be less than 300 MB")
    end
  end

  describe "acts_as_list" do
    it "maintains position ordering scoped to ai_experience" do
      attachment1 = attachment_model(context: course, size: 1.megabyte)
      attachment2 = attachment_model(context: course, size: 1.megabyte)

      cf1 = AiExperienceContextFile.create!(ai_experience:, attachment: attachment1)
      cf2 = AiExperienceContextFile.create!(ai_experience:, attachment: attachment2)

      expect(cf1.position).to eq(1)
      expect(cf2.position).to eq(2)
    end
  end
end
