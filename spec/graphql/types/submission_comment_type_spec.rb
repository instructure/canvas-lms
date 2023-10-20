# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../graphql_spec_helper"

describe Types::SubmissionCommentType do
  before(:once) do
    student_in_course(active_all: true)
    @student1 = @student
    student_in_course(active_all: true)
    @student2 = @student
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10, anonymous_peer_reviews: true
    @submission = @assignment.grade_student(@student1, score: 8, grader: @teacher)[0]
    @submission.update!(attempt: 2)
    @comment1 = @submission.add_comment(author: @student1, comment: "test", attempt: nil)
    @comment2 = @submission.add_comment(author: @student2, comment: "test2", attempt: 1)
    @comment3 = @submission.add_comment(author: @teacher, comment: "test3", attempt: 2)
    @submission_comments = @submission.submission_comments
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @teacher) }

  it "returns the comments for the current attempt" do
    expect(
      submission_type.resolve("commentsConnection { nodes { _id }}")
    ).to eq [@comment3.id.to_s]
  end

  describe "Submission Comment Read" do
    it "returns the correct read state" do
      @assignment.post_submissions
      expect(
        submission_type.resolve("commentsConnection { nodes { read }}")
      ).to eq [false]
    end

    it "returns the correct read state when submission is read" do
      @submission.mark_read(@teacher)
      expect(
        submission_type.resolve("commentsConnection { nodes { read }}")
      ).to eq [true]
      expect(
        submission_type.resolve(
          "commentsConnection { nodes { read }}",
          current_user: @student1
        )
      ).to eq [false]
    end

    it "returns the correct read state when submission comment is read" do
      @comment3.mark_read!(@teacher)
      expect(
        submission_type.resolve("commentsConnection { nodes { read }}")
      ).to eq [true]
      expect(
        submission_type.resolve(
          "commentsConnection { nodes { read }}",
          current_user: @student1
        )
      ).to eq [false]
    end
  end

  it "returns all the comments if allComments is true" do
    expect(
      submission_type.resolve("commentsConnection(filter: {allComments: true}) { nodes { _id }}")
    ).to eq(@submission_comments.map { |s| s.id.to_s })
  end

  it "author is only available if you have :read_author permission" do
    expect(
      submission_type.resolve(
        "commentsConnection(filter: {allComments: true}) { nodes { author { _id }}}",
        current_user: @student1
      )
    ).to eq [@student1.id.to_s, nil, @teacher.id.to_s]
  end

  it "returns an empty list if there are no attachments" do
    expect(
      submission_type.resolve(
        "commentsConnection(filter: {allComments: true}) { nodes { attachments { _id } }}"
      )
    ).to eq [[], [], []]
  end

  it "does not return attachments if they are not in the assignment" do
    a1 = attachment_model
    comment = @submission_comments[0]
    comment.attachments = [a1]
    comment.save!
    @submission.reload
    expect(
      submission_type.resolve(
        "commentsConnection(filter: {allComments: true}) { nodes { attachments { _id } }}"
      )
    ).to eq [[], [], []]
  end

  it "properly returns attachments if they are in the assignment" do
    a1 = attachment_model
    a2 = attachment_model
    @assignment.attachments << a1
    @assignment.attachments << a2
    comment = @submission_comments[0]
    comment.attachments = [a1, a2]
    comment.save!
    @submission.reload
    expect(
      submission_type.resolve(
        "commentsConnection(filter: {allComments: true}) { nodes { attachments { _id } }}"
      )
    ).to eq [[a1.id.to_s, a2.id.to_s], [], []]
  end

  it "handles multiple attachments in multiple comments" do
    a1 = attachment_model
    a2 = attachment_model
    a3 = attachment_model
    @assignment.attachments << a1
    @assignment.attachments << a2
    @assignment.attachments << a3

    comment1 = @submission_comments[0]
    comment1.attachments = [a1]
    comment1.save!

    comment2 = @submission_comments[1]
    comment2.attachments = [a2, a3]
    comment2.save!

    @submission.reload

    expect(
      submission_type.resolve(
        "commentsConnection(filter: {allComments: true}) { nodes { attachments { _id } }}"
      )
    ).to eq [[a1.id.to_s], [a2.id.to_s, a3.id.to_s], []]
  end

  describe "#media_object" do
    context "with no media object" do
      it "returns nil" do
        expect(submission_type.resolve(
                 'commentsConnection(filter: {allComments: true}) {
            nodes {
              mediaObject {
                title
              }
            }
          }'
               )).to eq([nil, nil, nil])
      end
    end

    context "with a valid media object" do
      before do
        @media_title = SecureRandom.hex
        @media_object = media_object(
          title: @media_title
        )
        @submission_comments[0].update!(
          media_comment_id: @media_object.media_id
        )
      end

      it "returns the media object for the comment" do
        expect(submission_type.resolve(
                 'commentsConnection(filter: {allComments: true}) {
            nodes {
              mediaObject {
                title
              }
            }
          }'
               )).to eq([@media_title, nil, nil])
      end
    end
  end

  describe "#attempt" do
    it "translates nil to zero" do
      expect(
        submission_type.resolve("commentsConnection(filter: {allComments: true}) { nodes { attempt }}")
      ).to eq [0, 1, 2]
    end
  end
end
