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
    # Create users with distinct names for better testing
    @student1 = User.create!(name: "Alice Student")
    @student2 = User.create!(name: "Bob Student")
    @teacher = User.create!(name: "Charlie Teacher")
    course_with_teacher(user: @teacher, active_all: true)
    @course.enroll_student(@student1, enrollment_state: :active)
    @course.enroll_student(@student2, enrollment_state: :active)
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

  it "returns the draft state" do
    expect(
      submission_type.resolve("commentsConnection { nodes { draft }}")
    ).to eq [false]
  end

  describe "comment" do
    before(:once) do
      @submission2 = @assignment.grade_student(@student2, score: 8, grader: @teacher)[0]
      @html_comment = @submission2.add_comment(author: @student2, comment: "<div>html comment</div>", attempt: nil)
      @html_submission_comments = @submission2.submission_comments
    end

    let(:submission_type2) { GraphQLTypeTester.new(@submission2, current_user: @teacher) }

    it "comment does not include html tags" do
      expect(
        submission_type2.resolve("commentsConnection(filter: {allComments: true}) { nodes { comment }}").first
      ).to eq("html comment")
    end

    it "html_comment includes html tags" do
      expect(
        submission_type2.resolve("commentsConnection(filter: {allComments: true}) { nodes { htmlComment }}").first
      ).to eq(@html_comment.comment)
    end

    it "does not throw an error for poorly formatted html" do
      @submission2.add_comment(
        author: @student2,
        comment: "<div>test invalid html comment</div></div>",
        attempt: nil
      )
      expect(
        submission_type2.resolve("commentsConnection(filter: {allComments: true}) { nodes { comment }}").last
      ).to eq("test invalid html comment")
    end
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

  describe "author_visible_name" do
    context "with moderated assignment" do
      before(:once) do
        @provisional_grader = User.create!(name: "Provisional Grader")
        @provisional_grader2 = User.create!(name: "Provisional Grader 2")
        @final_grader = User.create!(name: "Final Grader")
        @course.enroll_teacher(@provisional_grader, enrollment_state: :active)
        @course.enroll_teacher(@provisional_grader2, enrollment_state: :active)
        @course.enroll_teacher(@final_grader, enrollment_state: :active)

        @moderated_assignment = @course.assignments.create!(
          name: "Moderated Assignment",
          points_possible: 10,
          moderated_grading: true,
          grader_count: 2,
          final_grader: @final_grader,
          grader_names_visible_to_final_grader: true,
          grader_comments_visible_to_graders: true,
          graders_anonymous_to_graders: false,
          anonymous_grading: false
        )
        @moderated_assignment.grade_student(@student1, grade: 1, grader: @provisional_grader, provisional: true)
        @moderated_assignment.grade_student(@student1, grade: 2, grader: @final_grader, provisional: true)
        @moderated_assignment.grade_student(@student1, grade: 3, grader: @provisional_grader2, provisional: true)
        @moderated_submission = @moderated_assignment.submit_homework(@student1, body: "hello")

        @student_mod_comment = @moderated_submission.add_comment(author: @student1, comment: "student comment")
        @provisional_comment = @moderated_submission.add_comment(author: @provisional_grader, comment: "provisional comment", provisional: true)
        @provisional_comment2 = @moderated_submission.add_comment(author: @provisional_grader2, comment: "provisional comment 2", provisional: true)
        @final_comment = @moderated_submission.add_comment(author: @final_grader, comment: "final comment", provisional: true)
      end

      let(:moderated_submission_type) { GraphQLTypeTester.new(@moderated_submission, current_user: @final_grader) }
      let(:provisional_submission_type) { GraphQLTypeTester.new(@moderated_submission, current_user: @provisional_grader) }

      context "final grader/moderator" do
        it "returns anonymous grader name for provisional grader when final grader/moderator cannot view other grader names" do
          @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          result = moderated_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include(match(/Grader \d+/))
          expect(result).to include("Alice Student")
          expect(result).to include("Final Grader")
          expect(result).not_to include("Provisional Grader")
          expect(result).not_to include("Provisional Grader 2")
        end

        it "returns non-anonymous grader name for provisional grader when final grader/moderator can view other grader names" do
          @moderated_assignment.update!(grader_names_visible_to_final_grader: true)
          result = moderated_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include("Provisional Grader")
          expect(result).to include("Provisional Grader 2")
          expect(result).to include("Alice Student")
          expect(result).to include("Final Grader")
        end

        it "final grader can always see all comments" do
          @moderated_assignment.update!(grader_comments_visible_to_graders: false, graders_anonymous_to_graders: true, grader_names_visible_to_final_grader: false)
          result = moderated_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include("Alice Student")
          expect(result).to include("Final Grader")
          expect(result).to include(match(/Grader \d+/))
          expect(result).not_to include("Provisional Grader")
          expect(result).not_to include("Provisional Grader 2")
        end
      end

      context "provisional grader" do
        it "returns only student and comments from themselves when graders are not allowed to see other graders' comments" do
          @moderated_assignment.update!(grader_comments_visible_to_graders: false)
          result = provisional_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(2)
          expect(result).to include("Alice Student")
          expect(result).to include("Provisional Grader")
          expect(result).not_to include("Final Grader")
        end

        it "returns all comments when graders are allowed to see other graders' comments" do
          @moderated_assignment.update!(grader_comments_visible_to_graders: true)
          result = provisional_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include("Alice Student")
          expect(result).to include("Provisional Grader")
          expect(result).to include("Provisional Grader 2")
          expect(result).to include("Final Grader")
        end

        it "returns anonymous comments when graders are not allowed to see other graders' names" do
          @moderated_assignment.update!(graders_anonymous_to_graders: true, grader_comments_visible_to_graders: true)
          result = provisional_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include("Alice Student")
          expect(result).to include(match(/Grader \d+/))
          expect(result).to include("Provisional Grader")
          expect(result).not_to include("Provisional Grader 2")
          expect(result).not_to include("Final Grader")
        end

        it "returns non-anonymous comments when graders are allowed to see other graders' names" do
          @moderated_assignment.update!(graders_anonymous_to_graders: false, grader_comments_visible_to_graders: true)
          result = provisional_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
          )
          expect(result.length).to eq(4)
          expect(result).to include("Alice Student")
          expect(result).to include("Provisional Grader")
          expect(result).to include("Provisional Grader 2")
          expect(result).to include("Final Grader")
        end
      end

      context "when moderated assignment has anonymous grading" do
        before do
          @moderated_assignment.update!(anonymous_grading: true, grades_published_at: nil, graders_anonymous_to_graders: false)
        end

        context "final grader/moderator and provisional graders" do
          it "returns anonymous student names when assignment is anonymous and grades are not published" do
            result = provisional_submission_type.resolve(
              "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
            )
            expect(result.length).to eq(4)
            expect(result).to include(match(/Student \d+/))
            expect(result).to include("Provisional Grader")
            expect(result).to include("Provisional Grader 2")
            expect(result).to include("Final Grader")
          end

          it "returns real student names when assignment is anonymous and grades are published" do
            ModeratedGrading::ProvisionalGrade.find_by(submission: @moderated_submission, scorer: @final_grader).publish!
            @moderated_assignment.update!(grades_published_at: Time.zone.now)
            result = provisional_submission_type.resolve(
              "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
            )
            expect(result.length).to eq(4)
            expect(result).to include("Alice Student")
            expect(result).to include("Provisional Grader")
            expect(result).to include("Provisional Grader 2")
            expect(result).to include("Final Grader")
          end
        end
      end
    end

    context "with anonymous assignment" do
      before(:once) do
        @teacher1 = User.create!(name: "teacher 1 name")
        @teacher2 = User.create!(name: "teacher 2 name")
        @course.enroll_teacher(@teacher1, enrollment_state: :active)
        @course.enroll_teacher(@teacher2, enrollment_state: :active)

        @anonymous_assignment = @course.assignments.create!(
          name: "Anonymous Assignment",
          points_possible: 10,
          anonymous_grading: true
        )
        @anonymous_submission = @anonymous_assignment.submit_homework(@student1, body: "hello")

        @student_mod_comment = @anonymous_submission.add_comment(author: @student1, comment: "student comment")
        @teacher_comment = @anonymous_submission.add_comment(author: @teacher1, comment: "teacher comment")
        @teacher_comment2 = @anonymous_submission.add_comment(author: @teacher2, comment: "teacher comment 2")
      end

      let(:anonymous_submission_type) { GraphQLTypeTester.new(@anonymous_submission, current_user: @teacher1) }

      it "does not return student authors when assignment is anonymous" do
        result = anonymous_submission_type.resolve(
          "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { authorVisibleName }}"
        )
        expect(result.length).to eq(3)
        expect(result).to include(match(/Student \d+/))
        expect(result).to include("teacher 1 name")
        expect(result).to include("teacher 2 name")
      end
    end
  end

  describe "author" do
    context "with moderated assignment" do
      before(:once) do
        @provisional_grader = User.create!(name: "Provisional Grader")
        @provisional_grader2 = User.create!(name: "Provisional Grader 2")
        @final_grader = User.create!(name: "Final Grader")
        @course.enroll_teacher(@provisional_grader, enrollment_state: :active)
        @course.enroll_teacher(@provisional_grader2, enrollment_state: :active)
        @course.enroll_teacher(@final_grader, enrollment_state: :active)

        @moderated_assignment = @course.assignments.create!(
          name: "Moderated Assignment",
          points_possible: 10,
          moderated_grading: true,
          grader_count: 2,
          final_grader: @final_grader,
          grader_names_visible_to_final_grader: true,
          grader_comments_visible_to_graders: true,
          graders_anonymous_to_graders: false,
          anonymous_grading: false
        )
        @moderated_assignment.grade_student(@student1, grade: 1, grader: @provisional_grader, provisional: true)
        @moderated_assignment.grade_student(@student1, grade: 2, grader: @final_grader, provisional: true)
        @moderated_assignment.grade_student(@student1, grade: 3, grader: @provisional_grader2, provisional: true)
        @moderated_submission = @moderated_assignment.submit_homework(@student1, body: "hello")

        @student_mod_comment = @moderated_submission.add_comment(author: @student1, comment: "student comment")
        @provisional_comment = @moderated_submission.add_comment(author: @provisional_grader, comment: "provisional comment", provisional: true)
        @provisional_comment2 = @moderated_submission.add_comment(author: @provisional_grader2, comment: "provisional comment 2", provisional: true)
        @final_comment = @moderated_submission.add_comment(author: @final_grader, comment: "final comment", provisional: true)
      end

      let(:moderated_submission_type) { GraphQLTypeTester.new(@moderated_submission, current_user: @final_grader) }
      let(:provisional_submission_type) { GraphQLTypeTester.new(@moderated_submission, current_user: @provisional_grader) }
      let(:student_submission_type) { GraphQLTypeTester.new(@moderated_submission, current_user: @student1) }

      context "as a student" do
        it "returns author to comments they have permission to see when assignment is moderated" do
          @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          result = student_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { author { _id } }}"
          )
          expect(result).to eq([@student1.id.to_s])
        end
      end

      context "final grader/moderator" do
        it "does not return author when assignment is moderated" do
          @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          result = moderated_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { author { _id } }}"
          )
          expect(result).to eq([nil, nil, nil, nil])
        end
      end

      context "provisional grader" do
        it "does not return any authors when assignment is moderated" do
          @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          result = provisional_submission_type.resolve(
            "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { author { _id } }}"
          )
          expect(result).to eq([nil, nil, nil, nil])
        end
      end
    end

    context "with anonymous assignment" do
      before(:once) do
        @teacher1 = User.create!(name: "teacher 1 name")
        @teacher2 = User.create!(name: "teacher 2 name")
        @course.enroll_teacher(@teacher1, enrollment_state: :active)
        @course.enroll_teacher(@teacher2, enrollment_state: :active)

        @anonymous_assignment = @course.assignments.create!(
          name: "Anonymous Assignment",
          points_possible: 10,
          anonymous_grading: true
        )
        @anonymous_submission = @anonymous_assignment.submit_homework(@student1, body: "hello")

        @student_mod_comment = @anonymous_submission.add_comment(author: @student1, comment: "student comment")
        @teacher_comment = @anonymous_submission.add_comment(author: @teacher1, comment: "teacher comment")
        @teacher_comment2 = @anonymous_submission.add_comment(author: @teacher2, comment: "teacher comment 2")
      end

      let(:anonymous_submission_type) { GraphQLTypeTester.new(@anonymous_submission, current_user: @teacher1) }

      it "does not return student authors when assignment is anonymous" do
        result = anonymous_submission_type.resolve(
          "commentsConnection(filter: {allComments: true}, includeProvisionalComments: true) { nodes { author { name } }}"
        )
        expect(result).to eq([nil, "teacher 1 name", "teacher 2 name"])
      end
    end
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

  describe "#can_reply" do
    context "course account limits student access" do
      before(:once) do
        account = @submission.course.account
        account.settings[:enable_limited_access_for_students] = true
        account.save!
        account.root_account.enable_feature!(:allow_limited_access_for_students)
      end

      it "returns false for students" do
        expect(
          GraphQLTypeTester.new(@submission, current_user: @student1).resolve("commentsConnection(filter: {allComments: true}) { nodes { canReply }}")
        ).to eq [false, false, false]
      end

      it "returns true for teachers" do
        expect(
          submission_type.resolve("commentsConnection(filter: {allComments: true}) { nodes { canReply }}")
        ).to eq [true, true, true]
      end
    end

    context "course account does not limit student access" do
      it "returns true for students" do
        expect(
          GraphQLTypeTester.new(@submission, current_user: @student1).resolve("commentsConnection(filter: {allComments: true}) { nodes { canReply }}")
        ).to eq [true, true, true]
      end

      it "returns true for teachers" do
        expect(
          submission_type.resolve("commentsConnection(filter: {allComments: true}) { nodes { canReply }}")
        ).to eq [true, true, true]
      end
    end
  end
end
