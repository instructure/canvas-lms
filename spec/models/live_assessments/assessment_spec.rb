#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe LiveAssessments::Assessment do
  let_once(:assessment_context) { course_factory(active_all: true) }
  let_once(:assessment_user) { course_with_student(course: assessment_context, active_all: true).user }
  let_once(:assessor) { assessment_context.teachers.first }
  let_once(:another_assessment_user) { course_with_student(course: assessment_context, active_all: true).user }
  let_once(:assessment) { LiveAssessments::Assessment.create!(context: assessment_context, key: 'test key', title: 'test title') }
  let(:outcome) do
    outcome = assessment_context.created_learning_outcomes.create!(:description => 'this is a test outcome', :short_description => 'test outcome')
    assessment_context.root_outcome_group.add_outcome(outcome)
    assessment_context.root_outcome_group.save!
    assessment_context.reload
    outcome
  end
  let(:another_outcome) do
    outcome = assessment_context.created_learning_outcomes.create!(:description => 'this is another test outcome', :short_description => 'test outcome 2')
    assessment_context.root_outcome_group.add_outcome(outcome)
    assessment_context.root_outcome_group.save!
    assessment_context.reload
    outcome
  end

  describe '#generate_submissions_for' do
    it "doesn't do anything without aligned outcomes" do
      assessment.generate_submissions_for(assessment_user)
      expect(assessment.submissions.count).to eq 0
    end

    it "doesn't create a submission for users with no results" do
      outcome.align(assessment, assessment_context, mastery_type: 'none', mastery_score: 0.6)
      assessment.results.create!(user: assessment_user, assessor: assessor, passed: true, assessed_at: Time.now)
      assessment.generate_submissions_for([assessment_user, another_assessment_user])
      expect(assessment.submissions.count).to eq 1
    end

    it "creates a submission for each given user" do
      outcome.align(assessment, assessment_context, mastery_type: 'none', mastery_score: 0.6)
      assessment.results.create!(user: assessment_user, assessor: assessor, passed: true, assessed_at: Time.now)
      assessment.results.create!(user: another_assessment_user, assessor: assessor, passed: false, assessed_at: Time.now)
      assessment.generate_submissions_for([assessment_user, another_assessment_user])
      expect(assessment.submissions.count).to eq 2
      expect(assessment.submissions[0].possible).to eq 1
      expect(assessment.submissions[0].score).to eq 1
      expect(assessment.submissions[1].possible).to eq 1
      expect(assessment.submissions[1].score).to eq 0
    end

    it "updates existing submission" do
      outcome.align(assessment, assessment_context, mastery_type: 'none', mastery_score: 0.6)
      assessment.results.create!(user: assessment_user, assessor: assessor, passed: true, assessed_at: Time.now)
      assessment.generate_submissions_for([assessment_user])
      expect(assessment.submissions.count).to eq 1
      submission = assessment.submissions.first
      expect(submission.possible).to eq 1
      expect(submission.score).to eq 1
      assessment.results.create!(user: assessment_user, assessor: assessor, passed: false, assessed_at: Time.now)
      assessment.generate_submissions_for([assessment_user])
      expect(assessment.submissions.count).to eq 1
      expect(submission.reload.possible).to eq 2
      expect(submission.score).to eq 1
    end

    it "creates outcome results for each alignment" do
      alignment1 = outcome.align(assessment, assessment_context, mastery_type: 'none', mastery_score: 0.6)
      alignment2 = another_outcome.align(assessment, assessment_context, mastery_type: 'none', mastery_score: 0.5)
      LiveAssessments::Submission.any_instance.expects(:create_outcome_result).with(alignment1)
      LiveAssessments::Submission.any_instance.expects(:create_outcome_result).with(alignment2)
      assessment.results.create!(user: assessment_user, assessor: assessor, passed: true, assessed_at: Time.now)
      assessment.generate_submissions_for([assessment_user])
    end
  end
end
