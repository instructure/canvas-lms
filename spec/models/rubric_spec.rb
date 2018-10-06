#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Rubric do

  context "with outcomes" do
    before do
      outcome_with_rubric({mastery_points: 3})
    end

    before :once do
      assignment_model
    end

    def assessment_data(opts={})
      crit_id = "criterion_#{@rubric.data[0][:id]}"
      {
        user: @user,
        assessor: @user,
        artifact: @submission,
        assessment: {
          assessment_type: 'grading',
          "#{crit_id}": {
            points: opts[:points],
            comments: "cool, yo"
          }
        }
      }
    end

    it "should allow updating learning outcome criteria" do
      @outcome.short_description = 'alpha'
      @outcome.description = 'beta'
      criterion = {
        :mastery_points => 3,
        :ratings => [
          { :points => 7, :description => "Exceeds Expectations" },
          { :points => 3, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      }
      @outcome.rubric_criterion = criterion
      @rubric.update_learning_outcome_criteria(@outcome)
      rubric_criterion = @rubric.criteria_object.first
      expect(rubric_criterion.description).to eq 'alpha'
      expect(rubric_criterion.long_description).to eq 'beta'
      expect(rubric_criterion.ratings.length).to eq 3
      expect(rubric_criterion.ratings.map(&:description)).to eq [
        'Exceeds Expectations',
        'Meets Expectations',
        'Does Not Meet Expectations'
      ]
      expect(rubric_criterion.ratings.map(&:points)).to eq [7.0, 3.0, 0.0]
      expect(@rubric.points_possible).to eq 12
    end

    it "should allow learning outcome rows in the rubric" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
    end

    it "should delete learning outcome tags when they no longer exist" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @rubric.data[0][:learning_outcome_id] = nil
      @rubric.save!
      expect(@rubric.learning_outcome_alignments.active).to be_empty
    end

    it "should create learning outcome associations for multiple outcome rows" do
      outcome2 = @course.created_learning_outcomes.create!(:title => 'outcome2')
      @rubric.data[1][:learning_outcome_id] = outcome2.id
      @rubric.save!
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort).to eql([@outcome.id, outcome2.id].sort)
    end

    it "should create outcome results when outcome-aligned rubrics are assessed" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      user = user_factory(active_all: true)
      @course.enroll_student(user)
      a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments).not_to be_empty
      @submission = @assignment.grade_student(user, grade: "10", grader: @teacher).first
      a.assess(assessment_data({points: 2}))
      expect(@outcome.learning_outcome_results).not_to be_empty
      result = @outcome.learning_outcome_results.first
      expect(result.user_id).to be(user.id)
      expect(result.score).to be(2.0)
      expect(result.possible).to be(3.0)
      expect(result.original_score).to be(2.0)
      expect(result.original_possible).to be(3.0)
      expect(result.mastery).to be_falsey
      n = result.version_number
      a.assess(assessment_data({points: 3}))
      result.reload
      expect(result.version_number).to be > n
      expect(result.score).to be(3.0)
      expect(result.possible).to be(3.0)
      expect(result.original_score).to be(2.0)
      expect(result.mastery).to be_truthy
    end

    it "should destroy an outcome link after the assignment using it is destroyed (if it's not used anywhere else)" do
      outcome2 = @course.account.created_learning_outcomes.create!(:title => 'outcome')
      link = @course.root_outcome_group.add_outcome(outcome2)
      rubric = rubric_model
      rubric.data[0][:learning_outcome_id] = outcome2.id
      rubric.save!
      assignment2 = @course.assignments.create!(assignment_valid_attributes)
      rubric.associate_with(@assignment, @course, :purpose => 'grading')
      a2 = rubric.associate_with(assignment2, @course, :purpose => 'grading')

      assignment2.destroy
      expect(RubricAssociation.where(:id => a2).first).to be_nil # association should be destroyed

      rubric.reload
      expect(rubric).to be_active

      @assignment.destroy
      rubric.reload
      expect(rubric).to be_deleted

      link.reload
      expect(link.destroy).to be_truthy
    end
  end

  context "with fractional_points" do
    it "should allow fractional points" do
      course_factory
      data = [
        {
          :points => 0.5,
          :description => "Fraction row",
          :id => 1,
          :ratings => [
            { points: 0.5, description: "Rockin'", criterion_id: 1, id: 2 },
            { points: 0, description: "Lame", criterion_id: 1, id: 3 }
          ]
        }
      ]
      rubric = rubric_model({context: @course, data: data})
      expect(rubric.data.first[:points]).to be(0.5)
      expect(rubric.data.first[:ratings].first[:points]).to be(0.5)
    end
  end

  it "should be cool about duplicate titles" do
    course_with_teacher

    r1 = rubric_model({context: @course, title: "rubric"})
    expect(r1.title).to eql "rubric"

    r2 = rubric_model({context: @course, title: "rubric"})
    expect(r2.title).to eql "rubric (1)"

    r1.destroy

    r3 = rubric_model({context: @course, title: "rubric"})
    expect(r3.title).to eql "rubric"

    r3.title = "rubric"
    r3.save!
    expect(r3.title).to eql "rubric"
  end

  context "#update_with_association" do
    before :once do
      course_with_teacher
      assignment_model(points_possible: 20)
      @rubric = Rubric.new title: "r", context: @course
    end

    def test_rubric_associations(opts)
      expect(@rubric).to be_new_record
      # need to run the test 2x because the code path is different for new rubrics
      2.times do
        @rubric.update_with_association(@teacher, {
          id: @rubric.id,
          title: @rubric.title,
          criteria: {
            "0" => {
              description: "correctness",
              points: 15,
              ratings: {"0" => {points: 15, description: "asdf"}},
            },
          },
        }, @course, {
          association_object: @assignment,
          update_if_existing: true,
          use_for_grading: "1",
          purpose: "grading",
          skip_updating_points_possible: opts[:leave_different]
        })
        yield
      end
    end

    it "doesn't accidentally update assignment points" do
      test_rubric_associations(leave_different: true) do
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 20
      end
    end

    it "does update assignment points if you want it to" do
      test_rubric_associations(leave_different: false) do
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 15
      end
    end
  end

  describe "#destroy_for" do

    before do
      course_factory
      assignment_model
      rubric_model
    end

    it "does not destroy associations when deleted from an account" do
      @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @rubric.destroy_for(@course.account)
      expect(@rubric.rubric_associations).to be_present
    end

    it "destroys rubric associations within context when deleted from a course" do
      course_factory
      course1 = Course.first
      course2 = Course.last
      assignment2 = course2.assignments.create! title: "Assignment 2: Electric Boogaloo",
                                                points_possible: 20
      @rubric.associate_with(@assignment, course1, :purpose => 'grading')
      @rubric.associate_with(assignment2, course2, :purpose => 'grading')
      expect(@rubric.rubric_associations.length).to eq 2
      @rubric.destroy_for(course1)
      @rubric.reload
      expect(@rubric.rubric_associations.length).to eq 1
    end

    context 'when associated with a context containing an auditable assignment' do
      let(:course) { Course.create! }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:rubric) { Rubric.create!(title: 'hi', context: course) }

      let(:last_event) { AnonymousOrModerationEvent.where(event_type: 'rubric_deleted').last }

      before(:each) do
        rubric.update_with_association(teacher, {}, course, association_object: assignment)
      end

      it 'records a rubric_deleted AnonymousOrModerationEvent for the assignment' do
        expect { rubric.destroy_for(course, current_user: teacher) }.
          to change { AnonymousOrModerationEvent.where(event_type: 'rubric_deleted').count }.by(1)
      end

      it 'includes the ID of the destroyed rubric in the payload' do
        rubric.destroy_for(course, current_user: teacher)
        expect(last_event.payload['id']).to eq rubric.id
      end

      it 'includes the current user in the event data' do
        rubric.destroy_for(course, current_user: teacher)
        expect(last_event.user_id).to eq teacher.id
      end
    end
  end

  describe '#update_with_association' do
    let(:course) { Course.create! }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:assignment) { course.assignments.create!(anonymous_grading: true) }
    let(:rubric) { Rubric.create!(title: 'hi', context: course) }

    describe 'AnonymousOrModerationEvent creation for auditable assignments' do
      context 'when the assignment has a prior grading rubric' do
        let(:old_rubric) { Rubric.create!(title: 'zzz', context: course) }
        let(:last_updated_event) { AnonymousOrModerationEvent.where(event_type: 'rubric_updated').last }

        before(:each) do
          old_rubric.update_with_association(
            teacher,
            {},
            course,
            association_object: assignment,
            purpose: 'grading'
          )

          assignment.reload
        end

        it 'records a rubric_updated event for the assignment' do
          expect {
            rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          }.to change {
            AnonymousOrModerationEvent.where(event_type: 'rubric_updated').count
          }.by(1)
        end

        it 'includes the ID of the removed rubric in the payload' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_updated_event.payload['id'].first).to eq old_rubric.id
        end

        it 'includes the ID of the added rubric in the payload' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_updated_event.payload['id'].second).to eq rubric.id
        end

        it 'includes the updating user on the event' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_updated_event.user_id).to eq teacher.id
        end

        it 'includes the associated assignment on the event' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_updated_event.assignment_id).to eq assignment.id
        end
      end

      context 'when the assignment has no prior grading rubric' do
        let(:last_created_event) { AnonymousOrModerationEvent.where(event_type: 'rubric_created').last }

        it 'records a rubric_created event for the assignment' do
          expect {
            rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          }.to change {
            AnonymousOrModerationEvent.where(event_type: 'rubric_created', assignment: assignment).count
          }.by(1)
        end

        it 'includes the ID of the added rubric in the payload' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_created_event.payload['id']).to eq rubric.id
        end

        it 'includes the updating user on the event' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_created_event.user_id).to eq teacher.id
        end

        it 'includes the associated assignment on the event' do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: 'grading')
          expect(last_created_event.assignment_id).to eq assignment.id
        end
      end
    end
  end

  it "normalizes criteria for comparison" do
    criteria = [{:id => "45_392",
      :description => "Description of criterion",
      :long_description => "",
      :points => 5,
      :mastery_points => nil,
      :ignore_for_scoring => nil,
      :learning_outcome_migration_id => nil,
      :title => "Description of criterion",
      :ratings =>
        [{:description => "Full Marks",
          :id => "blank",
          :criterion_id => "45_392",
          :points => 5},
         {:description => "No Marks",
          :id => "blank_2",
          :criterion_id => "45_392",
          :points => 0}]}]
    expect(Rubric.normalize(criteria)).to eq(
      [{"description" => "Description of criterion",
        "points" => 5.0,
        "id" => "45_392",
        "ratings" =>
          [{"description" => "Full Marks",
            "points" => 5.0,
            "criterion_id" => "45_392",
            "id" => "blank"},
           {"description" => "No Marks",
            "points" => 0.0,
            "criterion_id" => "45_392",
            "id" => "blank_2"}]}]
    )
  end

  describe "#update_criteria" do
    context "populates blank titles" do
      before do
        rubric_model
        @rubric.update_criteria(
          criteria: {
            '0' => {
              description: '',
              ratings: {
                '0' => {
                  description: ''
                }
              }
            }
          }
        )
      end

      it "populates blank criterion title" do
        expect(@rubric.criteria[0][:description]).to eq 'No Description'
      end

      it "populates blank rating title" do
        expect(@rubric.criteria[0][:ratings][0][:description]).to eq 'No Description'
      end
    end
  end
end
