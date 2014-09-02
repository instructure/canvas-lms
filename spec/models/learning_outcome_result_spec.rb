#
# Copyright (C) 2011-2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe LearningOutcomeResult do

  let_once :learning_outcome_result do
    assignment_model
    outcome = @course.created_learning_outcomes.create!(title: 'outcome')

    LearningOutcomeResult.new(alignment: ContentTag.create!(title: 'content', context: @course)).tap do |lor|
      lor.association_object = quiz_model
      lor.context = @course
      lor.learning_outcome = outcome
      lor.associated_asset = quiz_model
      lor.save!
    end
  end

  describe '.association_type' do
    it 'returns the correct representation of a quiz' do
      learning_outcome_result.association_type.should == 'Quizzes::Quiz'

      learning_outcome_result.association_type = 'Quiz'
      learning_outcome_result.send(:save_without_callbacks)

      LearningOutcomeResult.first.association_type.should == 'Quizzes::Quiz'
    end

    it 'returns the association type attribute if not a quiz' do
      learning_outcome_result.association_object = assignment_model
      learning_outcome_result.send(:save_without_callbacks)
      learning_outcome_result.association_type.should == 'Assignment'
    end
  end

  describe '.artifact_type' do
    it 'returns the correct representation of a quiz submission' do
      sub = learning_outcome_result.association_object.quiz_submissions.create!

      learning_outcome_result.artifact = sub
      learning_outcome_result.save
      learning_outcome_result.artifact_type.should == 'Quizzes::QuizSubmission'

      LearningOutcomeResult.where(id: learning_outcome_result).update_all(association_type: 'QuizSubmission')

      LearningOutcomeResult.find(learning_outcome_result.id).artifact_type.should == 'Quizzes::QuizSubmission'
    end
  end

  describe '.associated_asset_type' do
    it 'returns the correct representation of a quiz' do
      learning_outcome_result.associated_asset_type.should == 'Quizzes::Quiz'

      learning_outcome_result.associated_asset_type = 'Quiz'
      learning_outcome_result.send(:save_without_callbacks)

      LearningOutcomeResult.first.associated_asset_type.should == 'Quizzes::Quiz'
    end

    it 'returns the associated asset type attribute if not a quiz' do
      learning_outcome_result.associated_asset = assignment_model
      learning_outcome_result.send(:save_without_callbacks)

      learning_outcome_result.associated_asset_type.should == 'Assignment'
    end
  end

end
