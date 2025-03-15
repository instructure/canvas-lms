# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe EstimatedDuration do
  describe "validations" do
    context "when all references are nil" do
      it "is invalid and adds an error" do
        estimated_duration = EstimatedDuration.new(duration: 1.hour + 30.minutes)
        expect(estimated_duration).not_to be_valid
        expect(estimated_duration.errors[:base]).to include("Exactly one reference must be present.")
      end
    end

    context "when two references are present" do
      let(:course) { Course.create! }

      it "is invalid and adds an error" do
        assignment = Assignment.create!(
          course:,
          name: "Some assignment"
        )
        quiz = Quizzes::Quiz.create!(title: "quiz1", context: course)
        estimated_duration = EstimatedDuration.new(assignment_id: assignment.id, quiz_id: quiz.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).not_to be_valid
        expect(estimated_duration.errors[:base]).to include("Exactly one reference must be present.")
      end
    end

    context "when at least one reference is present" do
      let(:course) { Course.create! }
      let(:user) { User.create! }

      it "is valid when assignment is present" do
        assignment = Assignment.create!(
          course:,
          name: "Some assignment"
        )
        estimated_duration = EstimatedDuration.create!(assignment_id: assignment.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(assignment.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.assignment.name).to eq(assignment.name)
      end

      it "is valid with quiz present" do
        quiz = Quizzes::Quiz.create!(title: "quiz1", context: course)
        estimated_duration = EstimatedDuration.create!(quiz_id: quiz.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(quiz.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.quiz.title).to eq(quiz.title)
      end

      it "is valid with wiki_page present" do
        wiki_page = WikiPage.create!(context: course, title: "Page 1")
        estimated_duration = EstimatedDuration.create!(wiki_page_id: wiki_page.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(wiki_page.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.wiki_page.title).to eq(wiki_page.title)
      end

      it "is valid with discussion_topic present" do
        discussion_topic = DiscussionTopic.create!(context: course,
                                                   pinned: true,
                                                   position: 21,
                                                   title: "Bar",
                                                   message: "baz")
        estimated_duration = EstimatedDuration.create!(discussion_topic_id: discussion_topic.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(discussion_topic.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.discussion_topic.title).to eq(discussion_topic.title)
      end

      it "is valid with attachment present" do
        attachment = Attachment.create!(user:,
                                        context: user,
                                        filename: "test.txt",
                                        uploaded_data: StringIO.new("first"))
        estimated_duration = EstimatedDuration.create!(attachment_id: attachment.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(attachment.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.attachment.filename).to eq(attachment.filename)
      end

      it "is valid with content_tag present" do
        account = Account.default
        outcome = account.created_learning_outcomes.create!(title: "outcome", description: "<p>This is <b>awesome</b>.</p>")
        content_tag = ContentTag.create!(content: outcome, context: account)
        estimated_duration = EstimatedDuration.create!(content_tag_id: content_tag.id, duration: 1.hour + 30.minutes)
        expect(estimated_duration).to be_valid
        expect(content_tag.estimated_duration.duration.iso8601).to eq("PT1H30M")
        expect(estimated_duration.content_tag.content.title).to eq(content_tag.content.title)
      end
    end
  end
end
