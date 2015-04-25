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
      expect(learning_outcome_result.association_type).to eq 'Quizzes::Quiz'

      learning_outcome_result.association_type = 'Quiz'
      learning_outcome_result.send(:save_without_callbacks)

      expect(LearningOutcomeResult.first.association_type).to eq 'Quizzes::Quiz'
    end

    it 'returns the association type attribute if not a quiz' do
      learning_outcome_result.association_object = assignment_model
      learning_outcome_result.send(:save_without_callbacks)
      expect(learning_outcome_result.association_type).to eq 'Assignment'
    end
  end

  describe '.artifact_type' do
    it 'returns the correct representation of a quiz submission' do
      sub = learning_outcome_result.association_object.quiz_submissions.create!

      learning_outcome_result.artifact = sub
      learning_outcome_result.save
      expect(learning_outcome_result.artifact_type).to eq 'Quizzes::QuizSubmission'

      LearningOutcomeResult.where(id: learning_outcome_result).update_all(association_type: 'QuizSubmission')

      expect(LearningOutcomeResult.find(learning_outcome_result.id).artifact_type).to eq 'Quizzes::QuizSubmission'
    end
  end

  describe '.associated_asset_type' do
    it 'returns the correct representation of a quiz' do
      expect(learning_outcome_result.associated_asset_type).to eq 'Quizzes::Quiz'

      learning_outcome_result.associated_asset_type = 'Quiz'
      learning_outcome_result.send(:save_without_callbacks)

      expect(LearningOutcomeResult.first.associated_asset_type).to eq 'Quizzes::Quiz'
    end

    it 'returns the associated asset type attribute if not a quiz' do
      learning_outcome_result.associated_asset = assignment_model
      learning_outcome_result.send(:save_without_callbacks)

      expect(learning_outcome_result.associated_asset_type).to eq 'Assignment'
    end
  end

  describe '#submitted_or_assessed_at' do
    before(:once) do
      @submitted_at = 1.month.ago
      @assessed_at = 2.weeks.ago
    end

    it 'returns #submitted_at when present' do
      learning_outcome_result.update_attribute(:submitted_at, @submitted_at)
      expect(learning_outcome_result.submitted_or_assessed_at).to eq(@submitted_at)
    end

    it 'returns #assessed_at when #submitted_at is not present' do
      learning_outcome_result.assign_attributes({
        assessed_at: @assessed_at,
        submitted_at: nil
      }, without_protection: true)
      expect(learning_outcome_result.submitted_or_assessed_at).to eq(@assessed_at)
    end

  end
end
