#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

describe MasterCourses::CollectionRestrictor do
  before :once do
    @copy_from = course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_bank = @copy_from.assessment_question_banks.create!
    @tag = @template.create_content_tag_for!(@original_bank)

    @copy_to = course_factory
    @bank_copy = @copy_to.assessment_question_banks.create!

    # doesn't actually need a migration_id - just delegates to the bank
    @aq = @bank_copy.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
    @bank_copy.migration_id = @tag.migration_id
    @bank_copy.save!
    @aq.reload
  end

  describe "column locking validations" do
    it "should not prevent changes if there are no restrictions" do
      @aq.question_data['question_text'] = "something else"
      @aq.save!
    end

    it "should not prevent changes to content columns on settings-locked objects" do
      @tag.update_attribute(:restrictions, {:settings => true})
      @aq.question_data['question_text'] = "something else"
      @aq.save!
    end

    it "should prevent changes to content columns on content-locked objects" do
      @tag.update_attribute(:restrictions, {:content => true})
      @aq.question_data['question_text'] = "something else"
      expect(@aq.save).to be_falsey
      expect(@aq.errors[:base].first.to_s).to include("locked by Master Course")
    end

    it "should allow new collection item if not locked" do
      @bank_copy.assessment_questions.create!(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
    end

    it "should not allow a new collection item if locked" do
      @tag.update_attribute(:restrictions, {:content => true})
      new_aq = @bank_copy.assessment_questions.new(:question_data => {'question_name' => 'test question', 'question_type' => 'essay_question'})
      expect(new_aq.save).to be_falsey
      expect(new_aq.errors[:base].first.to_s).to include("locked by Master Course")
    end

    it "should allow quiz questions to be generated and updated" do
      original_quiz = @copy_from.quizzes.create!
      quiz_tag = @template.create_content_tag_for!(original_quiz, :restrictions => {:content => true})

      quiz_copy = @copy_to.quizzes.create!(:migration_id => quiz_tag.migration_id)
      qq = quiz_copy.quiz_questions.create!(:question_data => {'some data' => '1'}, :workflow_state => "generated")

      qq.update_attribute(:question_data, {'some other data' => '1'})
    end
  end

  describe "editing_restricted?" do
    it "should return false by default" do
      expect(@aq.editing_restricted?(:any)).to be_falsey
      expect(@aq.editing_restricted?(:content)).to be_falsey
    end

    it "should return what you would expect" do
      @tag.update_attribute(:restrictions, {:content => true})
      expect(@aq.editing_restricted?(:content)).to be_truthy
      expect(@aq.editing_restricted?(:settings)).to be_falsey
      expect(@aq.editing_restricted?(:any)).to be_truthy
      expect(@aq.editing_restricted?(:all)).to be_truthy # in retrospect - if we're only classifying content as restricted then this should probably be true
    end
  end
end
