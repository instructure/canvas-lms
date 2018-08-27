#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes do
  let(:course) { Course.create! }

  it 'updates anonymous quizzes to no longer be anonymous' do
    anonymous_quiz = course.assignments.create!(anonymous_grading: true, submission_types: 'online_quiz')
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.to change { anonymous_quiz.reload.anonymous_grading? }.from(true).to(false)
  end

  it 'updates the updated_at on anonymous quizzes' do
    anonymous_quiz = course.assignments.create!(anonymous_grading: true, submission_types: 'online_quiz')
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.to change { anonymous_quiz.reload.updated_at }
  end

  it 'updates anonymous discussion topics to no longer be anonymous' do
    anonymous_discussion_topic = course.assignments.create!(
      anonymous_grading: true,
      submission_types: 'discussion_topic'
    )
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.to change { anonymous_discussion_topic.reload.anonymous_grading? }.from(true).to(false)
  end

  it 'updates the updated_at on anonymous discussion topics' do
    anonymous_discussion_topic = course.assignments.create!(
      anonymous_grading: true,
      submission_types: 'discussion_topic'
    )
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.to change { anonymous_discussion_topic.reload.updated_at }
  end

  it 'does not update anonymous assignments that are not quizzes or discussion topics to no longer be anonymous' do
    anonymous_assignment = course.assignments.create!(anonymous_grading: true)
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.not_to change { anonymous_assignment.reload.anonymous_grading? }
  end

  it 'does not update the updated_at for anonymous assignments that are not quizzes or discussion topics' do
    anonymous_assignment = course.assignments.create!(anonymous_grading: true)
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.not_to change { anonymous_assignment.reload.updated_at }
  end

  it 'does not update the updated_at for non-anonymous assignments that are not quizzes or discussion topics' do
    assignment = course.assignments.create!
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.not_to change { assignment.reload.updated_at }
  end

  it 'does not update the updated_at for non-anonymous quizzes' do
    quiz = course.assignments.create!(submission_types: 'online_quiz')
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.not_to change { quiz.reload.updated_at }
  end

  it 'does not update the updated_at for non-anonymous discussion topics' do
    discussion_topic = course.assignments.create!(submission_types: 'discussion_topic')
    expect {
      DataFixup::TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes.run
    }.not_to change { discussion_topic.reload.updated_at }
  end
end
