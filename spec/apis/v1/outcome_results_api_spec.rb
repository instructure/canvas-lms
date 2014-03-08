#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Outcome Results API", type: :request do

  let(:outcome_course) do
    course(active_all: true) unless @course
    @course
  end


  let(:outcome_teacher) do
    teacher_in_course(active_all: true) unless @teacher
    @teacher
  end

  let(:outcome_student) do
    student_in_course(active_all: true) unless @student
    @student
  end

  let(:outcome_rubric) do
    create_outcome_rubric unless @rubric
    @rubric
  end

  let(:outcome_object) do
    outcome_rubric unless @outcome
    @outcome
  end

  let(:outcome_assignment) do
    create_outcome_assignment
  end

  let(:outcome_rubric_association) do
    create_outcome_rubric_association
  end

  let(:outcome_submission) do
    find_or_create_outcome_submission
  end

  let(:outcome_criterion) do
    find_outcome_criterion
  end

  let(:first_outcome_rating) do # 3 points
    find_first_rating
  end

  let(:outcome_assessment) do
    create_outcome_assessment
  end

  def find_or_create_outcome_submission(opts = {})
    student = opts[:student] || outcome_student
    assignment = opts[:assignment] ||
      (opts[:association].assignment if opts[:association]) ||
      (create_outcome_assignment if opts[:new]) ||
      outcome_assignment
    assignment.find_or_create_submission(student)
  end

  def create_outcome_assessment(opts = {})
    association = opts[:association] ||
      (create_outcome_rubric_association(opts) if opts[:new]) ||
      outcome_rubric_association
    criterion = find_outcome_criterion(association.rubric)
    submission = opts[:submission] || find_or_create_outcome_submission(opts)
    student = submission.student
    points = opts[:points] ||
      find_first_rating(criterion)[:points]
    association.assess(
      user: student,
      assessor: outcome_teacher,
      artifact: submission,
      assessment: {
        assessment_type: 'grading',
        "criterion_#{criterion[:id]}".to_sym => {
          points: points
        }
      }
    )
  end

  def create_outcome_rubric
    outcome_course
    outcome_with_rubric(mastery_points: 3)
    @outcome.rubric_criterion = find_outcome_criterion
    @outcome.save
    @rubric
  end

  def create_outcome_assignment
    outcome_course.assignments.create!(
      title: "outcome assignment",
      description: "this is an outcome assignment",
      points_possible: outcome_rubric.points_possible,
    )
  end

  def create_outcome_rubric_association(opts = {})
    rubric = opts[:rubric] ||
      (create_outcome_rubric if opts[:new]) ||
      outcome_rubric
    assignment = opts[:assignment] ||
      (create_outcome_assignment if opts[:new]) ||
      outcome_assignment
    rubric.associate_with(assignment, outcome_course, purpose: 'grading', use_for_grading: true)
  end

  def find_outcome_criterion(rubric = outcome_rubric)
    rubric.criteria.find {|c| !c[:learning_outcome_id].nil? }
  end

  def find_first_rating(criterion = outcome_criterion)
    criterion[:ratings].first
  end

  let(:outcome_result) do
    outcome_assessment
    outcome_object.reload.learning_outcome_results.first
  end

  let(:outcome_students) do
    students = 0.upto(3).map do |i|
      student = student_in_course(active_all: true).user
      create_outcome_assessment(student: student, points: i)
      student
    end
  end

  let(:outcome_course_sections) do
    [0,1].map { |i| outcome_course.course_sections.create(name: "section #{i}") }
  end

  let(:sectioned_outcome_students) do
    0.upto(3).map do |i|
      student = student_in_section(outcome_course_sections[i % 2])
      create_outcome_assessment(student: student, points: i)
      student
    end
  end

  def outcome_rollups_url(context, params = {})
    api_v1_course_outcome_rollups_url(context, params)
  end

  def outcome_results_url(context, params = {})
    api_v1_course_outcome_results_url(context, params)
  end

  describe "outcome rollups" do
    describe "error handling" do
      it "requires manage grades permisssion" do
        course_with_student_logged_in
        raw_api_call(:get, outcome_rollups_url(outcome_course),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s)
        assert_status(403)
      end

      it "allows students to read their own results" do
        outcome_students
        @user = outcome_students[0]
        user_session(@user)
        raw_api_call(:get, outcome_rollups_url(outcome_course),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: outcome_course.id.to_s, user_ids: [outcome_students[0].id])
        assert_status(200)
      end

      it "does not allow students to read other users' results" do
        outcome_students
        @user = outcome_students[0]
        user_session(@user)
        raw_api_call(:get, outcome_rollups_url(outcome_course),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: outcome_course.id.to_s, user_ids: [outcome_students[1].id])
        assert_status(403)
      end

      it "does not allow students to read other users' results via csv" do
        outcome_students
        @user = outcome_students[0]
        user_session(@user)
        get "courses/#{@course.id}/outcome_rollups.csv"
        assert_status(403)
      end

      it "requires an existing context" do
        outcome_course
        course_with_teacher_logged_in(course: @course, active_all: true)
        bogus_course = Course.new { |c| c.id = -1 }
        raw_api_call(:get, outcome_rollups_url(bogus_course),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: bogus_course.id.to_s)
        assert_status(404)
      end

      it "verifies the aggregate parameter" do
        outcome_course
        course_with_teacher_logged_in(course: @course, active_all: true)
        raw_api_call(:get, outcome_rollups_url(@course, aggregate: 'invalid'),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: @course.id.to_s, aggregate: 'invalid')
        assert_status(400)
      end

      it "requires user ids to be students in the context" do
        outcome_course
        course_with_teacher_logged_in(course: @course, active_all: true)
        raw_api_call(:get, outcome_rollups_url(@course, user_ids: "#{@teacher.id}"),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: @course.id.to_s, user_ids: @teacher.id)
        assert_status(400)
      end

      it "requires section id to be a section in the context" do
        outcome_course
        bogus_section = course(active_course: true).course_sections.create!(name: 'bogus section')
        course_with_teacher_logged_in(course: outcome_course, active_all: true)
        raw_api_call(:get, outcome_rollups_url(outcome_course, section_id: bogus_section.id),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: @course.id.to_s, section_id: bogus_section.id.to_s)
        assert_status(400)
      end

      it "verifies the include[] parameter" do
        outcome_course
        course_with_teacher_logged_in(course: @course, active_all: true)
        raw_api_call(:get, outcome_rollups_url(@course, include: ['invalid']),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: @course.id.to_s, include: ['invalid'])
        assert_status(400)
      end
    end

    describe "basic response" do
      it "returns a json api structure" do
        outcome_student
        course_with_teacher_logged_in(course: @course, active_all: true)
        outcome_result
        api_call(:get, outcome_rollups_url(outcome_course),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s)
        json = JSON.parse(response.body)
        json.keys.sort.should == %w(meta rollups)
        json['rollups'].size.should == 1
        json['rollups'].each do |rollup|
          rollup.keys.sort.should == %w(links scores)
          rollup['links'].keys.sort.should == %w(section user)
          rollup['links']['section'].should == @course.course_sections.first.id.to_s
          rollup['links']['user'].should == outcome_student.id.to_s
          rollup['scores'].size.should == 1
          rollup['scores'].each do |score|
            score.keys.sort.should == %w(links score)
            score['score'].should == first_outcome_rating[:points]
            score['links'].keys.sort.should == %w(outcome)
            score['links']['outcome'].should == outcome_object.id.to_s
          end
        end
      end

      it "returns a csv file" do
        outcome_student
        course_with_teacher_logged_in(course: @course, active_all: true)
        outcome_result
        get "courses/#{@course.id}/outcome_rollups.csv"
        response.should be_success
        response.body.should == "Student name,Student ID,new outcome result,new outcome mastery points\n"+
          "User,#{outcome_student.id},3,3\n"
      end

      describe "user_ids parameter" do
        it "restricts results to specified users" do
          outcome_students
          student_ids = outcome_students[0..1].map(&:id).map(&:to_s)
          student_id_str = student_ids.join(',')
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, user_ids: student_id_str, include: ['users']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, user_ids: student_id_str, include: ['users'])
          json = JSON.parse(response.body)
          json.keys.sort.should == %w(linked meta rollups)
          json['rollups'].size.should == 2
          json['rollups'].each do |rollup|
            rollup.keys.sort.should == %w(links scores)
            rollup['links'].keys.sort.should == %w(section user)
            rollup['links']['section'].should == @course.course_sections.first.id.to_s
            student_ids.should be_include(rollup['links']['user'])
            rollup['scores'].size.should == 1
            rollup['scores'].each do |score|
              score.keys.sort.should == %w(links score)
              [0,1].should be_include(score['score'])
              score['links'].keys.sort.should == %w(outcome)
              score['links']['outcome'].should == outcome_object.id.to_s
            end
          end
          json['linked'].keys.sort.should == %w(users)
          json['linked']['users'].size.should == 2
        end
      end

      describe "section_id parameter" do
        it "restricts results to the specified section" do
          sectioned_outcome_students
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, section_id: outcome_course_sections[0].id, include: ['users']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, section_id: outcome_course_sections[0].id.to_s, include: ['users'])
          json = JSON.parse(response.body)
          json.keys.sort.should == %w(linked meta rollups)
          json['rollups'].size.should == 2
          json['rollups'].each do |rollup|
            rollup.keys.sort.should == %w(links scores)
            rollup['links'].keys.sort.should == %w(section user)
            rollup['links']['section'].should == outcome_course_sections[0].id.to_s
            outcome_course_sections[0].student_ids.map(&:to_s).should be_include(rollup['links']['user'])
            rollup['scores'].size.should == 1
            rollup['scores'].each do |score|
              score.keys.sort.should == %w(links score)
              [0,2].should be_include(score['score'])
              score['links'].keys.sort.should == %w(outcome)
              score['links']['outcome'].should == outcome_object.id.to_s
            end
          end
          json['linked'].keys.sort.should == %w(users)
          json['linked']['users'].size.should == outcome_course_sections[0].students.count
        end
      end

      describe "include[] parameter" do
        it "side loads courses" do
          outcome_object
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['courses'], aggregate: 'course'),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['courses'], aggregate: 'course')
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['courses'].should be_present
          json['linked']['courses'][0]['id'].should == outcome_course.id.to_s
        end

        it "side loads outcomes" do
          outcome_object
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['outcomes']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['outcomes'])
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['outcomes'].should be_present
          json['linked']['outcomes'][0]['id'].should == outcome_object.id.to_s
        end

        it "side loads outcome groups" do
          outcome_object
          root_group = outcome_course.root_outcome_group
          child_group = root_group.child_outcome_groups.create!(title: 'child group')
          grandchild_group = child_group.child_outcome_groups.create!(title: 'grandchild_group')
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['outcome_groups']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['outcome_groups'])
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['outcome_groups'].should be_present
          group_titles = json['linked']['outcome_groups'].map { |g| g['id'] }.sort
          expected_titles = [root_group, child_group, grandchild_group].map(&:id).map(&:to_s).sort
          group_titles.should == expected_titles
        end

        it "side loads outcome links" do
          outcome_object
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['outcome_links']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['outcome_links'])
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['outcome_links'].should be_present
          json['linked']['outcome_links'].first['outcome_group']['id'].should ==
            outcome_course.root_outcome_group.id.to_s
          json['linked']['outcome_links'].first['outcome']['id'].should ==
            outcome_object.id.to_s
        end

        it "side loads users" do
          outcome_assessment
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['users']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['users'])
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['users'].should be_present
          json['linked']['users'][0]['id'].should == outcome_student.id.to_s
        end

        it "side loads alignments" do
          outcome_assessment
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, include: ['outcomes', 'outcomes.alignments']),
                   controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, include: ['outcomes', 'outcomes.alignments'])
          json = JSON.parse(response.body)
          json['linked'].should be_present
          json['linked']['outcomes'].should be_present
          json['linked']['outcomes.alignments'].should be_present
          json['linked']['outcomes'][0]['alignments'].sort.should == [outcome_assignment.asset_string, outcome_rubric.asset_string]
          alignments = json['linked']['outcomes.alignments']
          alignments.sort_by!{|a| a['id']}
          alignments[0]['id'].should == outcome_assignment.asset_string
          alignments[0]['name'].should == outcome_assignment.name
          alignments[0]['html_url'].should == course_assignment_url(outcome_course, outcome_assignment)
          alignments[1]['id'].should == outcome_rubric.asset_string
          alignments[1]['name'].should == outcome_rubric.title
          alignments[1]['html_url'].should == course_rubric_url(outcome_course, outcome_rubric)
        end
      end
    end

    describe "outcomes" do
      before do
        @outcomes = 0.upto(3).map do |i|
          create_outcome_assessment(new: true)
          @outcome
        end
        @outcome_group = @course.learning_outcome_groups.create!(:title => 'groupage')
        @outcomes += 0.upto(2).map do |i|
          create_outcome_assessment(new: true)
          @outcome
        end
        course_with_teacher_logged_in(course: @course, active_all: true)
      end

      it "supports multiple outcomes" do
        api_call(:get, outcome_rollups_url(outcome_course),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s)
        json = JSON.parse(response.body)
        json['rollups'].size.should == 1
        rollup = json['rollups'][0]
        rollup['scores'].size.should == 7
      end

      it "filters by outcome id" do
        outcome_ids = @outcomes[3..4].map(&:id).map(&:to_s).sort
        api_call(:get, outcome_rollups_url(outcome_course, outcome_ids: outcome_ids.join(','), include: ['outcomes']),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, outcome_ids: outcome_ids.join(','), include: ['outcomes'])
        json = JSON.parse(response.body)
        json['linked']['outcomes'].size.should == outcome_ids.length
        json['linked']['outcomes'].map{|x| x['id']}.sort.should == outcome_ids
        rollup = json['rollups'][0]
        rollup['scores'].size.should == outcome_ids.length
      end

      it "filters by outcome group id" do
        outcome_ids = @outcome_group.child_outcome_links.map(&:content).map(&:id).map(&:to_s).sort
        api_call(:get, outcome_rollups_url(outcome_course, outcome_group_id: @outcome_group.id, include: ['outcomes']),
          controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s, outcome_group_id: @outcome_group.id, include: ['outcomes'])
        json = JSON.parse(response.body)
        json['linked']['outcomes'].size.should == outcome_ids.length
        json['linked']['outcomes'].map{|x| x['id']}.sort.should == outcome_ids
        rollup = json['rollups'][0]
        rollup['scores'].size.should == outcome_ids.length
      end
    end

    describe "aggregate response" do
      it "returns an aggregate json api structure" do
        outcome_student
        course_with_teacher_logged_in(course: @course, active_all: true)
        outcome_result
        api_call(:get, outcome_rollups_url(outcome_course, aggregate: 'course'),
          controller: 'outcome_results', action: 'rollups', format: 'json',
          course_id: outcome_course.id.to_s, aggregate: 'course')
        json = JSON.parse(response.body)
        json.keys.sort.should == %w(rollups)
        json['rollups'].size.should == 1
        json['rollups'].each do |rollup|
          rollup.keys.sort.should == %w(links scores)
          rollup['links']['course'] == @course.id.to_s
          rollup['scores'].size.should == 1
          rollup['scores'].each do |score|
            score.keys.sort.should == %w(links score)
            score['score'].should == first_outcome_rating[:points]
            score['links'].keys.sort.should == %w(outcome)
          end
        end
      end

      describe "user_ids parameter" do
        it "restricts aggregate to specified users" do
          outcome_students
          student_id_str = outcome_students[0..1].map(&:id).join(',')
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, aggregate: 'course', user_ids: student_id_str),
                   controller: 'outcome_results', action: 'rollups', format: 'json',
                   course_id: outcome_course.id.to_s, aggregate: 'course',
                   user_ids: student_id_str)
          json = JSON.parse(response.body)
          json.keys.sort.should == %w(rollups)
          json['rollups'].size.should == 1
          json['rollups'].each do |rollup|
            rollup.keys.sort.should == %w(links scores)
            rollup['links']['course'].should == @course.id.to_s
            rollup['scores'].size.should == 1
            rollup['scores'].each do |score|
              score.keys.sort.should == %w(links score)
              score['score'].should == 0.5
              score['links'].keys.sort.should == %w(outcome)
            end
          end
        end
      end

      describe "section_id parameter" do
        it "restricts aggregate to the specified section" do
          sectioned_outcome_students
          course_with_teacher_logged_in(course: outcome_course, active_all: true)
          api_call(:get, outcome_rollups_url(outcome_course, aggregate: 'course', section_id: outcome_course_sections[0].id),
                   controller: 'outcome_results', action: 'rollups', format: 'json',
                   course_id: outcome_course.id.to_s, aggregate: 'course',
                   section_id: outcome_course_sections[0].id.to_s)
          json = JSON.parse(response.body)
          json.keys.sort.should == %w(rollups)
          json['rollups'].size.should == 1
          json['rollups'].each do |rollup|
            rollup.keys.sort.should == %w(links scores)
            rollup['links']['course'].should == outcome_course.id.to_s
            rollup['scores'].size.should == 1
            rollup['scores'].each do |score|
              score.keys.sort.should == %w(links score)
              score['score'].should == 1
              score['links'].keys.sort.should == %w(outcome)
            end
          end
        end
      end
    end
  end

  describe "index" do
    # the filtering and inclusion logic is shared with the rollup endpoint, so we don't retest it here
    # we test some of that logic that is more specifically useful to the index endpoint
    it "side loads alignments" do
      outcome_assessment
      course_with_teacher_logged_in(course: outcome_course, active_all: true)
      api_call(:get, outcome_results_url(outcome_course, include: ['alignments']),
               controller: 'outcome_results', action: 'index', format: 'json', course_id: outcome_course.id.to_s, include: ['alignments'])
      json = JSON.parse(response.body)
      json['linked'].should be_present
      json['linked']['alignments'].should be_present
      json['linked']['alignments'][0]['id'].should == outcome_assignment.asset_string
    end

    it "returns outcome results" do
      outcome_assessment
      course_with_teacher_logged_in(course: outcome_course, active_all: true)
      api_call(:get, outcome_results_url(outcome_course),
               controller: 'outcome_results', action: 'index', format: 'json', course_id: outcome_course.id.to_s)
      json = JSON.parse(response.body)
      json['outcome_results'].should be_present
      json['outcome_results'][0]["id"].should == outcome_result.id.to_s
      json['outcome_results'][0]["score"].should == outcome_result.score
      json['outcome_results'][0]["links"]["learning_outcome"].should == outcome_object.id.to_s
      json['outcome_results'][0]["links"]["alignment"].should == outcome_assignment.asset_string
      json['outcome_results'][0]["links"]["user"].should == outcome_student.id.to_s
    end
  end

  describe "sharding" do
    specs_require_sharding

    it "returns results for users on multiple shards" do
      student = outcome_student
      outcome_assessment
      student2 = @shard2.activate { User.create!(name: 'outofshard') }
      enrollment = @course.enroll_student(student2, enrollment_state: 'active')
      create_outcome_assessment(student: student2)
      course_with_teacher_logged_in(course: @course, active_all: true)

      api_call(:get, outcome_rollups_url(outcome_course),
        controller: 'outcome_results', action: 'rollups', format: 'json', course_id: outcome_course.id.to_s)
      json = JSON.parse(response.body)
      json.keys.sort.should == %w(meta rollups)
      json['rollups'].size.should == 2
      json['rollups'].collect{|x| x['links']['user']}.sort.should == [student.id.to_s, student2.id.to_s].sort
      json['rollups'].each do |rollup|
        rollup.keys.sort.should == %w(links scores)
        rollup['scores'].size.should == 1
        rollup['links'].keys.sort.should == %w(section user)
      end
    end
  end

end
