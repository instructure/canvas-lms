#
# Copyright (C) 2014 Instructure, Inc.
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

describe LiveAssessments::Submission do
  let_once(:assessment_context) { course(active_all: true) }
  let(:outcome) do
    outcome = assessment_context.created_learning_outcomes.create!(:description => 'this is a test outcome', :short_description => 'test outcome')
    assessment_context.root_outcome_group.add_outcome(outcome)
    assessment_context.root_outcome_group.save!
    assessment_context.reload
    outcome
  end
  let(:alignment) { outcome.align(assessment, assessment_context, mastery_type: 'none') }
  let_once(:assessment_user) { course_with_student(course: assessment_context, active_all: true).user }
  let_once(:assessment) { LiveAssessments::Assessment.create(context: assessment_context, key: 'test key', title: 'test title') }
  let_once(:submission) { LiveAssessments::Submission.create(user: assessment_user, assessment: assessment, possible: 10, score: 5, assessed_at: Time.now) }

  describe '#create_outcome_result' do
    it 'does not create a result when no points are possible' do
      # we can probably create a meaningful result with no points
      # possible, but we don't now so that's what we test
      submission.possible = 0
      submission.create_outcome_result(alignment)
      result = alignment.learning_outcome_results.count.should == 0
    end

    it 'creates an outcome result' do
      submission.create_outcome_result(alignment)
      result = alignment.learning_outcome_results.first
      result.should_not be_nil
      result.title.should == "#{assessment_user.name}, #{assessment.title}"
      result.context.should == assessment.context
      result.artifact.should == submission
      result.assessed_at.to_i.should == submission.assessed_at.to_i
      result.score.should == submission.score
      result.possible.should == submission.possible
      result.percent.should == 0.5
      result.mastery.should be_nil
    end

    it 'updates an existing outcome result' do
      submission.create_outcome_result(alignment)
      result = alignment.learning_outcome_results.first
      result.percent.should == 0.5
      submission.score = 80
      submission.possible = 100
      submission.create_outcome_result(alignment)
      alignment.learning_outcome_results.count.should == 1
      result.reload.percent.should == 0.8
    end

    it "scales the score to the outcome rubric criterion if present" do
      outcome.data = {rubric_criterion: {mastery_points: 3, points_possible: 5}}
      outcome.save!
      submission.create_outcome_result(alignment)
      result = alignment.learning_outcome_results.first
      result.percent.should == 0.5
      result.score.should == 2.5
    end

    context 'alignment has a mastery score' do
      it 'sets mastery based on percent passed' do
        alignment.mastery_score = 0.6
        alignment.save!
        submission.create_outcome_result(alignment)
        result = alignment.learning_outcome_results.first
        result.mastery.should be_false
        submission.score = 80
        submission.possible = 100
        submission.create_outcome_result(alignment)
        alignment.learning_outcome_results.count.should == 1
        result.reload.mastery.should be_true
      end
    end
  end
end
