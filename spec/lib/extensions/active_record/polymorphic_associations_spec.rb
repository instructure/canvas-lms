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
#

describe Extensions::ActiveRecord::PolymorphicAssociations do
  context "with true polymorphic associations" do
    it "allows joins to specific classes" do
      # no error
      sql = StreamItem.joins(:discussion_topic).to_sql
      # and the sql
      expect(sql).to include("asset_type")
      expect(sql).to include("DiscussionTopic")
    end

    it "validates the type field" do
      si = StreamItem.new
      si.asset_type = "Submission"
      si.data = {}
      expect(si.valid?).to be true

      si.context_type = "User"
      expect(si.valid?).to be false
    end

    it "doesn't allow mismatched assignment" do
      si = StreamItem.new
      expect { si.discussion_topic = Course.new }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      expect { si.asset = Course.new }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      si.asset = DiscussionTopic.new
      si.asset = nil
    end

    it "has the same backing store for both generic and specific accessors" do
      si = StreamItem.new
      dt = DiscussionTopic.new
      si.discussion_topic = dt
      expect(si.asset_type).to eq "DiscussionTopic"
      expect(si.asset_id).to eq dt.id
      expect(si.asset.object_id).to eq si.discussion_topic.object_id
    end

    it "returns nil for the specific type if it's not that type" do
      si = StreamItem.new
      si.discussion_topic = DiscussionTopic.new
      expect(si.conversation).to be_nil
    end

    it "doesn't ignores specific type if we're setting nil" do
      si = StreamItem.new
      dt = DiscussionTopic.new
      si.discussion_topic = dt
      si.conversation = nil
      expect(si.asset).to eq dt
      si.discussion_topic = nil
      expect(si.asset).to be_nil
    end

    it "prefixes specific associations" do
      expect(AssessmentRequest.reflections.keys).to include("assessor_asset_submission")
    end

    it "prefixes specific associations with an explicit name" do
      expect(LearningOutcomeResult.reflections.keys).to include("association_assignment")
    end

    it "passes the correct foreign key down to specific associations" do
      expect(LearningOutcomeResult.reflections["association_assignment"].foreign_key.to_sym).to eq :association_id
    end

    it "handles class resolution that doesn't match the association name" do
      expect(Attachment.reflections["quiz"].klass).to eq Quizzes::Quiz
    end

    it "doesn't validate the type field for non-exhaustive associations" do
      u = User.create!
      v = Version.new
      v.versionable = u
      expect(v.versionable_type).to eq "User"
      expect(v).to be_valid
    end
  end

  context "with separate columns" do
    subject { AccessibilityResourceScan.new }

    let(:error_message) { "Exactly one context must be present" }

    context "validations" do
      context "with optional false" do
        subject { EstimatedDuration.new }

        context "when none of the context associations are set" do
          it "adds an error" do
            subject.valid?

            expect(subject.errors[:base]).to include(error_message)
          end
        end

        context "when multiple context associations are set" do
          it "adds an error" do
            subject.wiki_page = wiki_page_model
            subject.assignment = assignment_model
            subject.valid?

            expect(subject.errors[:base]).to include(error_message)
          end
        end
      end

      context "when only one context association is set" do
        %i[announcement assignment attachment discussion_topic wiki_page].each do |model|
          it "does not add an error for #{model}" do
            subject.public_send("#{model}=", public_send("#{model}_model"))
            subject.valid?

            expect(subject.errors[:base]).not_to include(error_message)
          end
        end
      end
    end

    context "context methods" do
      describe "#context" do
        %i[announcement assignment attachment discussion_topic wiki_page].each do |model|
          context "with #{model}" do
            let(:context) { public_send("#{model}_model") }

            it "returns the #{model}" do
              subject.public_send("#{model}=", context)
              expect(subject.context).to eq(context)
            end
          end
        end
      end

      describe "#context=" do
        %i[announcement assignment attachment discussion_topic wiki_page].each do |model|
          context "with #{model}" do
            let(:context) { public_send("#{model}_model") }

            it "sets the #{model}" do
              subject.context = context
              expect(subject.public_send(model)).to eq(context)
            end
          end
        end

        context "when context is not supported" do
          it "raises an error" do
            expect { subject.context = PluginSetting.new }.to(
              raise_error(TypeError, "PluginSetting is not one of Announcement, Assignment, Attachment, DiscussionTopic, WikiPage")
            )
          end
        end
      end
    end
  end
end
