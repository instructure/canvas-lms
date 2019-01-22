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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::SubmissionCommentType do
  before(:once) do
    student_in_course(active_all: true)
    @student1 = @student
    student_in_course(active_all: true)
    @student2 = @student
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10, anonymous_peer_reviews: true
    @submission = @assignment.grade_student(@student1, score: 8, grader: @teacher)[0]
    @submission.add_comment(author: @student1, comment: "test")
    @submission.add_comment(author: @student2, comment: "test2")
    @submission.add_comment(author: @teacher, comment: "test3")
    @submission_comments = @submission.submission_comments
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @teacher) }

  it "works" do
    expect(
      submission_type.resolve("commentsConnection { nodes { comment }}")
    ).to eq @submission_comments.map(&:comment)

    expect(
      submission_type.resolve("commentsConnection { nodes { _id }}")
    ).to eq @submission_comments.map(&:id).map(&:to_s)
  end

  it "author is only available if you have :read_author permission" do
    expect(
      submission_type.resolve("commentsConnection { nodes { author { _id }}}", current_user: @student1)
    ).to eq [@student1.id.to_s, nil, @teacher.id.to_s]
  end
end
