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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ContextModuleProgression do
  before do
    @course = course_factory(active_all: true)
    @module = @course.context_modules.create!(:name => "some module")

    @user = User.create!(:name => "some name")
    @course.enroll_student(@user).accept!
  end

  def setup_modules
    @assignment = @course.assignments.create!(:title => "some assignment")
    @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
    @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
    @module.workflow_state = 'unpublished'
    @module.save!

    @module2 = @course.context_modules.create!(:name => "another module")
    @module2.publish
    @module2.prerequisites = "module_#{@module.id}"
    @module2.save!

    @module3 = @course.context_modules.create!(:name => "another module again")
    @module3.publish
    @module3.save!
  end

  context "prerequisites_satisfied?" do
    before do
      setup_modules
    end

    it "should correctly ignore already-calculated context_module_prerequisites" do
      mp = @user.context_module_progressions.create!(:context_module => @module2)
      mp.workflow_state = 'locked'
      mp.save!
      mp2 = @user.context_module_progressions.create!(:context_module => @module)
      mp2.workflow_state = 'locked'
      mp2.save!

      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to eq true
    end

    it "should be satisfied if no prereqs" do
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to eq true
    end

    it "should be satisfied if prereq is unpublished" do
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to eq true
    end

    it "should be satisfied if prereq's prereq is unpublished" do
      @module3.prerequisites = "module_#{@module2.id}"
      @module3.save!
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to eq true
    end

    it "should be satisfied if dependent on both a published and unpublished module" do
      @module3.prerequisites = "module_#{@module.id}"
      @module3.prerequisites = [{:type=>"context_module", :id=>@module.id, :name=>@module.name}, {:type=>"context_module", :id=>@module2.id, :name=>@module2.name}]
      @module3.save!
      @module3.reload
      expect(@module3.prerequisites.count).to eq 2

      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module3)).to eq true
    end

    it "should skip incorrect prereq hashes" do
      @module3.prerequisites = [{:type=>"context_module", :id=>@module.id},
                                {:type=>"not_context_module", :id=>@module2.id, :name=>@module2.name}]
      @module3.save!

      expect(@module3.prerequisites.count).to eq 0
    end

    it "should update when publishing or unpublishing" do
      @module.publish
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to eq false
      @module.unpublish
      expect(ContextModuleProgression.prerequisites_satisfied?(@user, @module2)).to eq true
    end
  end

  context '#evaluate' do
    let(:module_progression) do
      p = @module.context_module_progressions.create do |p|
        p.context_module = @module
        p.user = @user
        p.current = true
        p.evaluated_at = 5.minutes.ago
      end
      p.workflow_state = 'bogus'
      p
    end

    context 'does not evaluate' do
      before { module_progression.evaluated_at = Time.now }

      it 'when current' do
        module_progression.evaluate

        expect(module_progression.workflow_state).to eq 'bogus'
      end

      it 'when current and the module has not yet unlocked' do
        @module.unlock_at = 10.minutes.from_now
        module_progression.evaluate

        expect(module_progression.workflow_state).to eq 'bogus'
      end
    end

    context 'does evaluate' do
      it 'when not current' do
        module_progression.current = false
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq 'bogus'
      end

      it 'when current, but the evaluated_at stamp is missing' do
        module_progression.evaluated_at = nil
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq 'bogus'
      end

      it 'when current, but the module has since unlocked' do
        @module.unlock_at = 1.minute.ago
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq 'bogus'
      end

      it 'when current, but the module has been updated' do
        module_progression.evaluated_at = 1.minute.ago
        module_progression.evaluate

        expect(module_progression.workflow_state).not_to eq 'bogus'
      end
    end
  end

  context "optimistic locking" do
    def stale_progression
      progression = @user.context_module_progressions.create!(context_module: @module)
      ContextModuleProgression.find(progression.id).update_attribute(:updated_at, 10.seconds.ago)
      progression
    end

    it "raises a stale object error during save" do
      progression = stale_progression
      expect { progression.update_attribute(:updated_at, 10.seconds.from_now) }.to raise_error(ActiveRecord::StaleObjectError)
      expect { progression.reload.update_attribute(:updated_at, 10.seconds.from_now) }.to_not raise_error
    end

    it 'raises a stale object error during evaluate' do
      progression = stale_progression
      expect { progression.evaluate }.to raise_error(ActiveRecord::StaleObjectError)
      expect { progression.reload.evaluate }.to_not raise_error
    end

    it 'does not raise a stale object error during evaluate!' do
      progression = stale_progression
      expect { progression.evaluate! }.to_not raise_error
    end

    it 'does not raise a stale object error during catastrophic evaluate!' do
      progression = stale_progression
      allow(progression).to receive(:save).at_least(:once).and_raise(ActiveRecord::StaleObjectError.new(progression, 'Save'))

      new_progression = nil
      expect { new_progression = progression.evaluate! }.to_not raise_error
      expect(new_progression.workflow_state).to eq 'locked'
    end
  end

  it "should not invalidate progressions if a prerequisite changes, until manually relocked" do
    @module.unpublish!
    setup_modules
    @module3.prerequisites = "module_#{@module2.id}"
    @module3.save!
    progression2 = @module2.evaluate_for(@user)
    progression3 = @module3.evaluate_for(@user)

    @module.reload
    @module.publish!
    progression2.reload
    progression3.reload
    expect(progression2).to be_completed
    expect(progression3).to be_completed

    @module.relock_progressions

    progression2.reload
    progression3.reload
    expect(progression2).to be_locked
    expect(progression3).to be_locked
  end

  describe "#uncomplete_requirement" do
    it "should uncomplete the requirement" do
      setup_modules
      @module.publish!
      progression = @tag.context_module_action(@user, :read)
      progression.uncomplete_requirement(@tag.id)
      expect(progression.requirements_met.length).to be(0)

    end

    it "should not change anything when given an ID that does not exist" do
      setup_modules
      @module.publish!
      progression = @tag.context_module_action(@user, :read)
      progression.uncomplete_requirement(-1)
      expect(progression.requirements_met.length).to be(1)
    end
  end

  it "should update progressions when adding a must_contribute requirement on a topic" do
    @assignment = @course.assignments.create!
    @tag1 = @module.add_item({:id => @assignment.id, :type => 'assignment'})
    @topic = @course.discussion_topics.create!
    entry = @topic.discussion_entries.create!(:user => @user)
    @module.completion_requirements = {@tag1.id => {:type => 'must_view'}}

    progression = @module.evaluate_for(@user)
    expect(progression).to be_unlocked

    @tag2 = @module.add_item({:id => @topic.id, :type => 'discussion_topic'})
    @module.update_attribute(:completion_requirements, {@tag1.id => {:type => 'must_view'}, @tag2.id => {:type => 'must_contribute'}})

    progression.reload
    expect(progression).to be_started

    expect_any_instantiation_of(@topic).to receive(:recalculate_context_module_actions!).never # doesn't recalculate unless it's a new requirement
    @module.update_attribute(:completion_requirements, {@tag1.id => {:type => 'must_submit'}, @tag2.id => {:type => 'must_contribute'}})
  end

  context "assignment muting" do
    it "should work with muted assignments" do
      assignment = @course.assignments.create(:title => "some assignment", :points_possible => 100, :submission_types => "online_text_entry")
      assignment.mute!
      tag = @module.add_item({:id => assignment.id, :type => 'assignment'})
      @module.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      assignment.submit_homework(@user, :body => "blah")
      assignment.grade_student(@user, :score => 85, :grader => @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank
      assignment.grade_student(@user, :score => 95, :grader => @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank

      assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "should complete when the assignment is unmuted after a grade is assigned without a submission" do
      assignment = @course.assignments.create(:title => "some assignment", :points_possible => 100, :submission_types => "online_text_entry")
      assignment.mute!
      tag = @module.add_item({:id => assignment.id, :type => 'assignment'})
      @module.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      # no submission here
      assignment.grade_student(@user, :score => 100, :grader => @teacher)
      expect(progression.reload).to be_started
      expect(progression.requirements_met).to be_blank

      assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "should work with muted quiz assignments" do
      quiz = @course.quizzes.create(:title => "some quiz", :quiz_type => "assignment", :scoring_policy => 'keep_highest', :workflow_state => 'available')
      quiz.assignment.mute!
      tag = @module.add_item({:id => quiz.id, :type => 'quiz'})
      @module.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      quiz_sub = quiz.generate_submission(@user)
      quiz_sub.update_attributes(:score => 100, :workflow_state => 'complete', :submission_data => nil)
      quiz_sub.with_versioning(&:save)
      expect(progression.reload).to be_started

      quiz.assignment.unmute!
      expect(progression.reload).to be_completed
    end

    it "should work with muted discussion assignments" do
      topic = @course.discussion_topics.create(:title => "some topic")
      assignment = assignment_model(:course => @course, :points_possible => 100)
      topic.assignment = assignment
      topic.save!
      assignment.reload

      assignment.mute!
      tag = @module.add_item({:id => topic.id, :type => 'discussion_topic'})
      @module.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 90}}
      @module.save!

      progression = @module.evaluate_for(@user)
      expect(progression).to be_unlocked

      entry = topic.reply_from(:user => @user, :text => "entry")
      expect(progression.reload).to be_started
      assignment.grade_student(@user, :score => 100, :grader => @teacher)
      expect(progression.reload).to be_started

      assignment.unmute!
      expect(progression.reload).to be_completed
    end
  end
end
