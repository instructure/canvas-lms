#
# Copyright (C) 2011-2016 Instructure, Inc.
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

require_relative '../api_spec_helper'

module AssignmentGroupsApiSpecHelper
  def setup_groups
    @group1 = @course.assignment_groups.create!(name: 'group1')
    @group1.update_attribute(:position, 10)
    @group1.update_attribute(:group_weight, 40)
    @group2 = @course.assignment_groups.create!(name: 'group2')
    @group2.update_attribute(:position, 7)
    @group2.update_attribute(:group_weight, 60)
  end

  def setup_four_assignments(assignment_opts = {})
    @a1 = @course.assignments.create!(
      {
        title: "test1",
        assignment_group: @group1,
        points_possible: 10,
        description: 'Assignment 1'
      }.merge(assignment_opts)
    )
    @a2 = @course.assignments.create!(
      {
        title: "test2",
        assignment_group: @group1,
        points_possible: 12,
        description: 'Assignment 2'
      }.merge(assignment_opts)
    )
    @a3 = @course.assignments.create!(
      {
        title: "test3",
        assignment_group: @group2,
        points_possible: 8,
        description: 'Assignment 3'
      }.merge(assignment_opts)
    )
    @a4 = @course.assignments.create!(
      {
        title: "test4",
        assignment_group: @group2,
        points_possible: 9,
        description: 'Assignment 4'
      }.merge(assignment_opts)
    )
  end

  def setup_grading_periods
    setup_groups
    @group1_assignment_today = @course.assignments.create!(assignment_group: @group1, due_at: Time.zone.now)
    @group1_assignment_future = @course.assignments.create!(assignment_group: @group1, due_at: 3.months.from_now)
    @group2_assignment_today = @course.assignments.create!(assignment_group: @group2, due_at: Time.zone.now)
    gpg = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
    @gp_current = gpg.grading_periods.create!(
      title: 'current',
      weight: 50,
      start_date: 1.month.ago,
      end_date: 1.month.from_now
    )
    @gp_future = gpg.grading_periods.create!(
      title: 'future',
      weight: 50,
      start_date: 2.months.from_now,
      end_date: 4.months.from_now
    )
  end
end

describe AssignmentGroupsController, type: :request do
  include Api
  include Api::V1::Assignment
  include AssignmentGroupsApiSpecHelper

  before :once do
    course_with_teacher(active_all: true)
  end

  it "sorts the returned list of assignment groups" do
    # the API returns the assignments sorted by
    # assignment_groups.position
    group1 = @course.assignment_groups.create!(name: 'group1')
    group1.update_attribute(:position, 10)
    group2 = @course.assignment_groups.create!(name: 'group2')
    group2.update_attribute(:position, 7)
    group3 = @course.assignment_groups.create!(name: 'group3')
    group3.update_attribute(:position, 12)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s })

    expect(json).to eq [
      {
        'id' => group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'group_weight' => 0,
        'sis_source_id' => nil,
        'integration_data' => {}
      },
      {
        'id' => group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'group_weight' => 0,
        'sis_source_id' => nil,
        'integration_data' => {}
      },
      {
        'id' => group3.id,
        'name' => 'group3',
        'position' => 12,
        'rules' => {},
        'group_weight' => 0,
        'sis_source_id' => nil,
        'integration_data' => {}
      }
    ]
  end

  it "should include full assignment jsonification when specified" do
    setup_groups
    setup_four_assignments

    rubric_model(user: @user, context: @course, points_possible: 12,
                                     data: larger_rubric_data)

    @a3.create_rubric_association(rubric: @rubric, purpose: 'grading', use_for_grading: true)

    @a4.submission_types = 'discussion_topic'
    @a4.save!
    [@a1, @a2, @a3, @a4].each(&:reload)

    @course.update_attribute(:group_weighting_scheme, 'percent')

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments'] })

    expected = [
      {
        'group_weight' => 60.0,
        'id' => @group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'any_assignment_in_closed_grading_period' => false,
        'integration_data' => {},
        'sis_source_id' => nil,
        'assignments' => [
          controller.assignment_json(@a3,@user,session).as_json,
          controller.assignment_json(@a4,@user,session, include_discussion_topic: false).as_json
        ]
      },
      {
        'group_weight' => 40.0,
        'id' => @group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'any_assignment_in_closed_grading_period' => false,
        'integration_data' => {},
        'sis_source_id' => nil,
        'assignments' => [
          controller.assignment_json(@a1,@user,session).as_json,
          controller.assignment_json(@a2,@user,session).as_json
        ]
      }
    ]

    json.each do |group|
      group["assignments"].each do |assignment|
        expect(assignment).to have_key "description"
      end
    end

    expect(json).to eq expected
  end

  it "optionally includes 'grades_published' for moderated assignments" do
    group = @course.assignment_groups.create!(name: "Homework")
    group.update_attribute(:position, 10)

    @course.assignments.create!({
      assignment_group: group,
      description: "First Math Assignment",
      points_possible: 10,
      title: "Math 1.1"
    })

    json = api_call(
      :get,
      "/api/v1/courses/#{@course.id}/assignment_groups.json",
      {
        action: "index",
        controller: "assignment_groups",
        course_id: @course.id.to_s,
        format: "json",
        include: ["assignments", "grades_published"]
      }
    )

    expect(json.first["assignments"].first["grades_published"]).to eq(true)
  end

  context "exclude response fields" do
    before(:once) do
      setup_groups
      setup_four_assignments
    end

    it "excludes the descriptions of assignments if 'description' is included " \
    "in the exclude_response_fields param" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignment_groups.json?" \
                      "include[]=assignments&exclude_response_fields[]=description",
                      { controller: 'assignment_groups', action: 'index',
                        format: 'json', course_id: @course.id.to_s,
                        include: ['assignments'],
                        exclude_response_fields: ['description']
      })

      json.each do |group|
        group["assignments"].each { |a| expect(a).not_to have_key "description" }
      end
    end

    it "excludes the needs_grading_count of assignments if " \
    "'needs_grading_count' is included in the exclude_response_fields param" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignment_groups.json?" \
                      "include[]=assignments&exclude_response_fields[]=needs_grading_count",
                      { controller: 'assignment_groups', action: 'index',
                        format: 'json', course_id: @course.id.to_s,
                        include: ['assignments'],
                        exclude_response_fields: ['needs_grading_count']
      })

      json.each do |group|
        group["assignments"].each { |a| expect(a).not_to have_key "needs_grading_count" }
      end
    end
  end

  context "differentiated assignments" do
    it "should only return visible assignments when differentiated assignments is on" do
      setup_groups
      setup_four_assignments(only_visible_to_overrides: true)
      @user.enrollments.each(&:destroy_permanently!)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @user)
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      # make a1 and a3 visible
      create_section_override_for_assignment(@a1, course_section: @section)
      @a3.grade_student(@user, grade: 10, grader: @teacher)

      [@a1, @a2, @a3, @a4].each(&:reload)

      json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments'] })

      json.each do |ag_json|
        expect(ag_json["assignments"].length).to eq 1
      end
    end

    it "should allow designers to see unpublished assignments" do
      setup_groups
      setup_four_assignments(only_visible_to_overrides: true)
      course_with_designer(course: @course)
      [@a1,@a3].each(&:unpublish)

      json = api_call_as_user(@designer, :get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments'] })

      json.each do |ag_json|
        expect(ag_json["assignments"].length).to eq 2
      end
    end

    it "should include assignment_visibility when requested" do
      @course.assignments.create!
      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/assignment_groups.json",
        {
        controller: 'assignment_groups', action: 'index',
          format: 'json', course_id: @course.id.to_s
        },
        include: ['assignments', 'assignment_visibility']
      )
      json.each do |ag|
        ag["assignments"].each do |a|
          expect(a.has_key?("assignment_visibility")).to eq true
        end
      end
    end
  end

  context "grading periods" do
    before :once do
      setup_grading_periods
    end

    describe "#index" do
      let(:api_path) { "/api/v1/courses/#{@course.id}/assignment_groups" }
      let(:api_settings) do
        {
          controller: 'assignment_groups', action: 'index', format: 'json',
          course_id: @course.id.to_s, grading_period_id: @gp_future.id.to_s,
          include: ['assignments']
        }
      end

      it "should only return assignments within the grading period" do
        json = api_call(:get, api_path, api_settings)
        expect(json[1]['assignments'].length).to eq 1
      end

      it "should not return assignments outside the grading period" do
        json = api_call(:get, api_path, api_settings)
        expect(json[0]['assignments'].length).to eq 0
      end
    end

    describe "#show" do
      it "should only return assignments and submissions within the grading period" do
        student = User.create!
        @course.enroll_student(student)
        api_path = "/api/v1/courses/#{@course.id}/assignment_groups/#{@group1.id}"
        api_settings = {
          controller: 'assignment_groups_api', action: 'show', format: 'json',
          course_id: @course.id, grading_period_id: @gp_future.id,
          assignment_group_id: @group1.id, include: ['assignments', 'submission']
        }
        @group1_assignment_future.grade_student(student, grade: 10, grader: @teacher)
        @group1_assignment_today.grade_student(student, grade: 8, grader: @teacher)
        json = api_call_as_user(student, :get, api_path, api_settings)
        expect(json["assignments"].length).to eq(1)
        expect(json["assignments"].first["submission"]).to be_present
      end
    end

  end

  context 'when module_ids are requested' do
    before :each do
      @mods = Array.new(2) { |i| @course.context_modules.create! name: "Mod#{i}" }
      g = @course.assignment_groups.create! name: 'assignments'
      a = @course.assignments.create! assignment_group: g, title: 'blah'
      @mods.each { |m| m.add_item type: 'assignment', id: a.id }

      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments&include[]=module_ids",
        { controller: 'assignment_groups', action: 'index',
          format: 'json', course_id: @course.id.to_s,
          include: %w[assignments module_ids]})

      @assignment_json = json.first["assignments"].first
    end

    it 'includes module_ids' do
      expect(@assignment_json['module_ids'].sort).to eq @mods.map(&:id).sort
    end

    it 'includes module_positions' do
      expect(@assignment_json['module_positions']).to eq([1, 1])
    end
  end

  it "should not include all dates" do
    group = @course.assignment_groups.build(name: 'group1')
    group.position = 10
    group.group_weight = 40
    group.save!

    a1 = @course.assignments.create!(title: "test1", assignment_group: group, points_possible: 10)
    a2 = @course.assignments.create!(title: "test2", assignment_group: group, points_possible: 12)

    a1.assignment_overrides.create! do |override|
      override.set = @course.course_sections.first
      override.title = "All"
      override.due_at = 1.day.ago
      override.due_at_overridden = true
    end

    # catch updated timestamps
    a1.reload
    a2.reload

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments'] })

    expected = [
      {
        'group_weight' => 40.0,
        'id' => group.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'any_assignment_in_closed_grading_period' => false,
        'integration_data' => {},
        'sis_source_id' => nil,
        'assignments' => [
          controller.assignment_json(a1, @user,session).as_json,
          controller.assignment_json(a2, @user,session).as_json
        ]
      }
    ]

    expect(json).to eq expected
  end

  it "should include all dates" do
    group = @course.assignment_groups.build(name: 'group1')
    group.position = 10
    group.group_weight = 40
    group.save!

    a1 = @course.assignments.create!(title: "test1", assignment_group: group, points_possible: 10)
    a2 = @course.assignments.create!(title: "test2", assignment_group: group, points_possible: 12)

    a1.assignment_overrides.create! do |override|
      override.set = @course.course_sections.first
      override.title = "All"
      override.due_at = 1.day.ago
      override.due_at_overridden = true
    end
    a1.reload

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments&include[]=all_dates",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments', 'all_dates'] })

    expected = [
      {
        'group_weight' => 40.0,
        'id' => group.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'any_assignment_in_closed_grading_period' => false,
        'integration_data' => {},
        'sis_source_id' => nil,
        'assignments' => [
          controller.assignment_json(a1, @user,session, include_all_dates: true).as_json,
          controller.assignment_json(a2, @user,session, include_all_dates: true).as_json
        ]
      }
    ]

    expect(json).to eq expected
  end

  it "should exclude deleted assignments" do
    group1 = @course.assignment_groups.create!(name: 'group1')
    group1.update_attribute(:position, 10)

    @course.assignments.create!(title: "test1", assignment_group: group1, points_possible: 10)
    a2 = @course.assignments.create!(title: "test2", assignment_group: group1, points_possible: 12)
    a2.destroy

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { controller: 'assignment_groups', action: 'index',
            format: 'json', course_id: @course.id.to_s,
            include: ['assignments'] })

    group = json.first
    expect(group).to be_present
    expect(group['assignments'].size).to eq 1
    expect(group['assignments'].first['name']).to eq 'test1'
  end

  it "should return weights that aren't being applied" do
    @course.update_attribute(:group_weighting_scheme, 'equal')

    @course.assignment_groups.create!(name: 'group1', group_weight: 50)
    @course.assignment_groups.create!(name: 'group2', group_weight: 50)

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups",
                    { controller: 'assignment_groups', action: 'index',
                      format: 'json', course_id: @course.to_param })

    json.each { |group| expect(group['group_weight']).to eq 50 }
  end

  it "should not explode on assignments with <objects> with percentile widths" do
    group = @course.assignment_groups.create!(name: 'group')
    assignment = @course.assignments.create!(title: "test", assignment_group: group, points_possible: 10)
    assignment.description = '<object width="100%" />'
    assignment.save!

    api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
             controller: 'assignment_groups',
             action: 'index',
             format: 'json',
             course_id: @course.id.to_s,
             include: ['assignments'])
  end

  it "should not return unpublished assignments to students" do
    student_in_course(active_all: true)
    @course.require_assignment_group
    assignment = @course.assignments.create! do |a|
      a.title = "test"
      a.assignment_group = @course.assignment_groups.first
      a.points_possible = 10
      a.workflow_state = "unpublished"
    end
    expect(assignment).to be_unpublished

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
                    controller: 'assignment_groups',
                    action: 'index',
                    format: 'json',
                    course_id: @course.id.to_s,
                    include: ['assignments'])
    expect(json.first['assignments']).to be_empty
  end
end


describe AssignmentGroupsApiController, type: :request do
  include Api
  include Api::V1::Assignment
  include AssignmentGroupsApiSpecHelper

  let(:name)             { "Awesome group name" }
  let(:position)         { 1 }
  let(:integration_data) { {"my existing" => "data", "more" => "data"} }

  let(:params) do
    {
      'name'             => name,
      'position'         => position,
      'integration_data' => integration_data
    }
  end

  let(:invalid_integration_data) { 'invalid integration data format' }

  let(:assignment_group) do
    rules_in_db = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
    @course.assignment_groups.create!(name: 'group', rules: rules_in_db)
  end

  context '#show' do
    before :once do
      course_with_teacher(active_all: true)
      rules_in_db = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
      @group = @course.assignment_groups.create!(name: 'group', rules: rules_in_db)
    end

    it 'should succeed' do
      response = raw_api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{assignment_group.id}",
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: assignment_group.id.to_s)

      expect(response).to eq(200)
    end

    it 'should fail if the assignment group does not exist' do
      non_existing_assignment_group_id = assignment_group.id + 1
      response = raw_api_call(:get,
        "/api/v1/courses/#{@course.id}/assignment_groups/#{non_existing_assignment_group_id}",
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: non_existing_assignment_group_id)

      expect(response).to eq(404)
    end

    context 'with assignments' do
      before(:once) do
        @assignment = @course.assignments.create!({
          title: "test",
          assignment_group: @group,
          points_possible: 10
        })
      end

      it 'should include assignments' do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}?include[]=assignments",
          controller: 'assignment_groups_api',
          action: 'show',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_group_id: @group.id.to_s,
          include: ['assignments'])

        expect(json['assignments']).not_to be_empty
      end

      it 'should include submission when flag is present' do
        student_in_course(active_all: true)
        teacher_in_course(active_all: true, course: @course)
        @submission = bare_submission_model(@assignment, @student, {
          score: '25',
          grade: '25',
          grader_id: @teacher.id,
          submitted_at: Time.zone.now
        })

        json = api_call_as_user(@student, :get,
          "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}?include[]=assignments&include[]=submission",
          controller: 'assignment_groups_api',
          action: 'show',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_group_id: @group.id.to_s,
          include: ['assignments', 'submission'])

        expect(json['assignments'][0]['submission']).to be_present
        expect(json['assignments'][0]['submission']['id']).to eq @submission.id
      end
    end

    it 'should only return assignments in the given grading period with MGP on' do
      setup_grading_periods

      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group1.id}?include[]=assignments&grading_period_id=#{@gp_future.id}",
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @group1.id.to_s,
        grading_period_id: @gp_future.id.to_s,
        include: ['assignments'])

      expect(json['assignments'].length).to eq 1
    end

    it 'should not return an error when there are grading periods and no grading_period_id is passed in' do
      setup_grading_periods

      api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group1.id}?include[]=assignments",
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @group1.id.to_s,
        include: ['assignments'])

      expect(response).to be_ok
    end

    it "should include assignment_visibility when requested and with DA on" do
      @course.assignments.create!(title: "test", assignment_group: @group, points_possible: 10)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}.json",
        {
        controller: 'assignment_groups_api',
          action: 'show',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_group_id: @group.id.to_s
        },
        include: ['assignments', 'assignment_visibility']
      )
      json['assignments'].each do |a|
        expect(a.has_key?("assignment_visibility")).to eq true
      end
    end

    it "should not include assignment_visibility when requested as a student" do
      student_in_course(active_all: true)
      @course.assignments.create!(title: "test", assignment_group: @group, points_possible: 10)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}.json",
        {
        controller: 'assignment_groups_api',
          action: 'show',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_group_id: @group.id.to_s
        },
        include: ['assignments', 'assignment_visibility']
      )
      json['assignments'].each do |a|
        expect(a.has_key?("assignment_visibility")).to eq false
      end
    end

    it 'should return never_drop rules as strings with Accept header' do
      rules = {'never_drop' => ["1","2"], 'drop_lowest' => 1, 'drop_highest' => 1}
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}", {
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @group.id.to_s},
        {},
        { 'Accept' => 'application/json+canvas-string-ids' })

      expect(json['rules']).to eq rules
    end

    it 'should return never_drop rules as ints without Accept header' do
      rules = {'never_drop' => [1,2], 'drop_lowest' => 1, 'drop_highest' => 1}
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}", {
        controller: 'assignment_groups_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @group.id.to_s}
        )

      expect(json['rules']).to eq rules
    end
  end

  context '#create' do
    before do
      course_with_teacher(active_all: true)
    end

    it 'should create an assignment_group' do
      api_call(:post, "/api/v1/courses/#{@course.id}/assignment_groups", {
        controller: 'assignment_groups_api',
          action: 'create',
          format: 'json',
          course_id: @course.id.to_s},
          params)
      assignment_group = AssignmentGroup.last
      expect(assignment_group.name).to eq(name)
      expect(assignment_group.position).to eq(position)
      expect(assignment_group.integration_data).to eq(integration_data)
    end

    it 'does not create an assignment_group with invalid integration_data' do
      params['integration_data'] = invalid_integration_data

      expect do
        raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignment_groups", {
          controller: 'assignment_groups_api',
            action: 'create',
            format: 'json',
            course_id: @course.id.to_s},
            params)
      end.to change(AssignmentGroup, :count).by(0)
    end

    it 'responds with a 400 when invalid integration_data is included' do
      params['integration_data'] = invalid_integration_data

      response = raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignment_groups", {
        controller: 'assignment_groups_api',
        action: 'create',
        format: 'json',
        course_id: @course.id.to_s},
        params)

      expect(response).to eq(400)
    end
  end

  context '#update' do
    let(:assignment_group) do
      @course.assignment_groups.create!(params)
    end

    let(:updated_name)             { "Newer Awesome group name" }
    let(:updated_position)         { 2 }
    let(:updated_integration_data) { {"new" => "datum", "v2" => "fractal"} }

    let(:updated_params) do
      {
        'name'             => updated_name,
        'position'         => updated_position,
        'integration_data' => updated_integration_data
      }
    end

    let(:put_url) { "/api/v1/courses/#{@course.id}/assignment_groups/#{assignment_group.id}" }

    let(:api_details) do
      {
        controller: 'assignment_groups_api',
        action: 'update',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: assignment_group.id.to_s
      }
    end

    before :once do
      course_with_teacher(active_all: true)
      @assignment_group = @course.assignment_groups.create!(name: 'Some group',
                                                            position: 1,
                                                            integration_data: {"oh" => 'hello'})
    end

    it 'should update an assignment group' do
      response = api_call(:put, put_url, api_details, updated_params)

      # Check the api response
      expect(response['name']).to eq(updated_name)
      expect(response['position']).to eq(updated_position)
      expect(response['integration_data']).to eq(integration_data.merge(updated_integration_data))

      # Check the db record
      assignment_group.reload
      expect(assignment_group.name).to eq(updated_name)
      expect(assignment_group.position).to eq(updated_position)
      expect(assignment_group.integration_data).to eq(integration_data.merge(updated_integration_data))
    end

    it 'should update an assignment group when integration_data is nil' do
      updated_params['integration_data'] = nil
      response = api_call(:put, put_url, api_details, updated_params)

      # Check the api response
      expect(response['name']).to eq(updated_name)
      expect(response['integration_data']).to eq(integration_data)

      # Check the db record
      assignment_group.reload
      expect(assignment_group.name).to eq(updated_name)
      expect(assignment_group.integration_data).to eq(integration_data)
    end

    it 'should update an assignment group when integration_data is {}' do
      updated_params['integration_data'] = {}
      response = api_call(:put, put_url, api_details, updated_params)

      # Check the api response
      expect(response['name']).to eq(updated_name)
      expect(response['integration_data']).to eq(integration_data)

      # Check the db record
      assignment_group.reload
      expect(assignment_group.name).to eq(updated_name)
      expect(assignment_group.integration_data).to eq(integration_data)
    end

    it 'should update an assignment group without integration_data' do
      updated_params.delete('integration_data')
      response = api_call(:put, put_url, api_details, updated_params)

      # Check the api response
      expect(response['name']).to eq(updated_name)
      expect(response['integration_data']).to eq(integration_data)

      # Check the db record
      assignment_group.reload
      expect(assignment_group.name).to eq(updated_name)
      expect(assignment_group.integration_data).to eq(integration_data)
    end

    it 'does not update when integration_data is malformed' do
      updated_params['integration_data'] = invalid_integration_data
      raw_api_call(:put, put_url, api_details, updated_params)

      # Check the db record
      assignment_group.reload
      expect(assignment_group.name).to eq(name)
      expect(assignment_group.position).to eq(position)
      expect(assignment_group.integration_data).to eq(integration_data)
    end

    it 'returns a 400 when integration data is malformed' do
      updated_params['integration_data'] = invalid_integration_data
      response = raw_api_call(:put, put_url, api_details, updated_params)
      expect(response).to eq(400)
    end

    it 'should update rules properly' do
      rules = {'never_drop' => ["1","2"], 'drop_lowest' => 1, 'drop_highest' => 1}
      rules_in_db = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
      params = {'rules' => rules}
      json = api_call(:put, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}", {
        controller: 'assignment_groups_api',
        action: 'update',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @assignment_group.id.to_s},
        params,
        { 'Accept' => 'application/json+canvas-string-ids' })

      expect(json['rules']).to eq rules
      @assignment_group.reload
      expect(@assignment_group.rules).to eq rules_in_db
    end

    context "when an assignment is due in a closed grading period" do
      let(:call_update) do
        -> (params, expected_status) do
          api_call_as_user(
            @current_user,
            :put, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}",
            {
              controller: 'assignment_groups_api',
              action: 'update',
              format: 'json',
              course_id: @course.id.to_s,
              assignment_group_id: @assignment_group.id.to_s
            },
            params,
            { 'Accept' => 'application/json+canvas-string-ids' },
            { expected_status: expected_status }
          )
        end
      end

      before :once do
        @grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        @grading_period_group.enrollment_terms << @course.enrollment_term
        Factories::GradingPeriodHelper.new.create_for_group(@grading_period_group, {
          start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
        })
        @assignment_group.update_attributes(group_weight: 50)
      end

      context "as a teacher" do
        before :each do
          @current_user = @teacher
          student_in_course(course: @course, active_all: true)
          @assignment = @course.assignments.create!({
            title: 'assignment',
            assignment_group: @assignment_group,
            due_at: 1.week.ago,
            workflow_state: 'published'
          })
        end

        it "cannot change group_weight" do
          params = { group_weight: 75 }
          call_update.call(params, 401)
          expect(@assignment_group.reload.group_weight).to eq(50)
        end

        it "cannot change rules" do
          rules_hash = { "never_drop" => ["1", "2"], "drop_lowest" => 1, "drop_highest" => 1 }
          @assignment_group.rules_hash = rules_hash
          @assignment_group.save
          rules_encoded = @assignment_group.rules
          call_update.call({ rules: { drop_lowest: "1" } }, 401)
          expect(@assignment_group.reload.rules).to eq(rules_encoded)
        end

        it "succeeds when group_weight is not changed" do
          call_update.call({ group_weight: 50 }, 200)
          expect(@assignment_group.reload.group_weight).to eq(50)
        end

        it "succeeds when rules have not changed" do
          rules_hash = { "never_drop" => ["1", "2"], "drop_lowest" => 1, "drop_highest" => 1 }
          @assignment_group.rules_hash = rules_hash
          @assignment_group.save
          rules_encoded = @assignment_group.rules
          call_update.call({ rules: rules_hash }, 200)
          expect(@assignment_group.reload.rules).to eq(rules_encoded)
        end

        it "ignores deleted assignments" do
          @assignment.destroy
          call_update.call({ group_weight: 75 }, 200)
          expect(@assignment_group.reload.group_weight).to eq(75)
        end
      end

      context "as an admin" do
        it "can change group_weight" do
          @course.assignments.create!({
            title: 'assignment', assignment_group: @assignment_group, due_at: 1.week.ago
          })
          @current_user = account_admin_user(account: @course.root_account)
          call_update.call({ group_weight: 75 }, 200)
          expect(@assignment_group.reload.group_weight).to eq(75)
        end
      end
    end
  end

  context '#destroy' do
    before :once do
      course_with_teacher(active_all: true)
      @assignment_group = @course.assignment_groups.create!(name: 'Some group', position: 1)
    end

    it 'should destroy an assignment group' do

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}",
        controller: 'assignment_groups_api',
        action: 'destroy',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @assignment_group.id.to_s)

      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
    end

    it 'should destroy assignments' do
      a1 = @course.assignments.create!(title: "test1", assignment_group: @assignment_group, points_possible: 10)
      a2 = @course.assignments.create!(title: "test2", assignment_group: @assignment_group, points_possible: 12)

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}",
        controller: 'assignment_groups_api',
        action: 'destroy',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @assignment_group.id.to_s)

      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
      expect(a1.reload.workflow_state).to eq 'deleted'
      expect(a2.reload.workflow_state).to eq 'deleted'
    end

    it 'should move assignments to a specified assignment group' do
      @course.assignment_groups.create!(name: 'Another group', position: 2)
      group3 = @course.assignment_groups.create!(name: 'Yet Another group', position: 3)

      @course.assignments.create!(title: "test1", assignment_group: @assignment_group, points_possible: 10)
      @course.assignments.create!(title: "test2", assignment_group: @assignment_group, points_possible: 12)
      @course.assignments.create!(title: "test3", assignment_group: @assignment_group, points_possible: 8)
      @course.assignments.create!(title: "test4", assignment_group: @assignment_group, points_possible: 9)

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}", {
        controller: 'assignment_groups_api',
        action: 'destroy',
        format: 'json',
        course_id: @course.id.to_s,
        assignment_group_id: @assignment_group.id.to_s},
        {move_assignments_to: group3.id})

      group3.reload
      expect(group3.assignments.count).to eq 4
      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
    end
  end
end
