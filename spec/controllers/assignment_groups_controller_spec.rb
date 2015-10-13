#
# Copyright (C) 2011 Instructure, Inc.
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

require_relative '../spec_helper'

describe AssignmentGroupsController do
  def course_group
    @group = @course.assignment_groups.create(:name => 'some group')
  end

  describe 'GET index' do
    describe 'filteing by grading period and overrides' do
      let!(:assignment) { course.assignments.create!(due_at: Date.new(2015, 1, 15)) }
      let!(:assignment_with_override) { course.assignments.create!(due_at: Date.new(2015, 1, 15)) }
      let!(:feb_override) do
        # mass assignment is disabled for AssigmentOverride
        assignment_with_override.assignment_overrides.new.tap do |override|
          override.title =  'feb override'
          override.due_at = Time.zone.local(2015, 2, 15)
        end.save!
      end

      let(:jan_grading_period) do
        grading_period_group.grading_periods.create!(
          start_date: Date.new(2015, 1, 1),
          end_date: Date.new(2015, 1, 31),
          title: 'Jan Period'
        )
      end

      let(:feb_grading_period) do
        grading_period_group.grading_periods.create!(
          start_date: Date.new(2015, 2, 1),
          end_date: Date.new(2015, 2, 28),
          title: 'Feb Period'
        )
      end

      let(:grading_period_group) { course.grading_period_groups.create! }
      let(:course) { Course.create! }
      let(:root_account) { Account.default }
      let(:sub_account) { root_account.sub_accounts.create! }

      context 'given a root account with a grading period and a sub account with a grading period' do
        before do
          root_account.allow_feature!(:multiple_grading_periods)
          root_account.enable_feature!(:multiple_grading_periods)
          root_account.enable_feature!(:differentiated_assignments)

          account_admin_user(account: root_account)
          user_session(@admin)
        end

        it 'when there is an assignment with overrides, filter grading periods by overrides due_at' do
          get :index,
           course_id: course.id,
           include: ['assignments', 'assignment_visibility', 'overrides'],
           override_assignment_dates: false,
           exclude_descriptions: true,
           grading_period_id: feb_grading_period.id,
           format: :json

          json = JSON.parse(response.body[9..-1])
          assignments_ids = json.first['assignments'].map{|a| a['id']}
          expect(assignments_ids).to include assignment_with_override.id
          expect(assignments_ids).to_not include assignment.id
        end
      end
    end

    context 'given a course with teach and a student in course' do
      before :once do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
      end

      it 'requires authorization' do
        get 'index', :course_id => @course.id
        assert_unauthorized
      end

      context 'differentiated assignments' do
        before do
          user_session(@teacher)
          course_group
          @group = course_group
          @course.enable_feature!(:differentiated_assignments)
          @assignment = @course.assignments.create!(
            title: 'assignment',
            assignment_group: @group,
            only_visible_to_overrides: true,
            workflow_state: 'published'
          )
        end

        it 'does not check visibilities on individual assignemnts' do
          # ensures that check is not an N+1 from the gradebook
          Assignment.any_instance.expects(:students_with_visibility).never
          get 'index', :course_id => @course.id, :include => ['assignments','assignment_visibility'], :format => :json
          expect(response).to be_success
        end
      end

      context 'multiple grading periods feature enabled' do
        before do
          @course.root_account.enable_feature!(:multiple_grading_periods)
          user_session(@teacher)
        end

        it 'does not throw an error when grading_period_id is passed in as empty string' do
          get 'index', :course_id => @course.id, :include => ['assignments', 'assignment_visibility'], :grading_period_id => '', :format => :json
          expect(response).to be_success
        end
      end
    end
  end

  describe "POST 'reorder'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it 'requires authorization' do
      post 'reorder', :course_id => @course.id
      assert_unauthorized
    end

    it 'does not allow students to reorder' do
      user_session(@student)
      post 'reorder', :course_id => @course.id
      assert_unauthorized
    end

    it 'reorders assignment groups' do
      user_session(@teacher)
      groups = 3.times.map { course_group }
      expect(groups.map(&:position)).to eq [1, 2, 3]
      g1, g2, _ = groups
      post 'reorder', :course_id => @course.id, :order => "#{g2.id},#{g1.id}"
      expect(response).to be_success
      groups.each(&:reload)
      expect(groups.map(&:position)).to eq [2, 1, 3]
    end

  end

  describe "POST 'reorder_assignments'"do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @group1 = @course.assignment_groups.create!(:name => 'group 1')
      @group2 = @course.assignment_groups.create!(:name => 'group 2')
      @assignment1 = @course.assignments.create!(:title => 'assignment 1', :assignment_group => @group1)
      @assignment2 = @course.assignments.create!(:title => 'assignment 2', :assignment_group => @group1)
      @assignment3 = @course.assignments.create!(:title => 'assignment 3', :assignment_group => @group2)
      @order = "#{@assignment1.id},#{@assignment2.id},#{@assignment3.id}"
    end

    it 'requires authorization' do
      post :reorder_assignments, :course_id => @course.id, :assignment_group_id => @assignment1.assignment_group.id, :order => @order
      assert_unauthorized
    end

    it 'does not allow students to reorder' do
      user_session(@student)
      post :reorder_assignments, :course_id => @course.id, :assignment_group_id => @assignment1.assignment_group.id, :order => @order
      assert_unauthorized
    end

    it 'moves the assingment from its current assignment group to another assignment group' do
      user_session(@teacher)
      expect(response).to be_success
      post :reorder_assignments, :course_id => @course.id, :assignment_group_id => @assignment1.assignment_group.id, :order => @order
      @assignment3.reload
      expect(@assignment3.assignment_group_id).to eq(@group1.id)
      expect(@group2.assignments.count).to eq(0)
      expect(@group1.assignments.count).to eq(3)
    end
  end

  describe "GET 'show'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    it 'requires authorization' do
      get 'show', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it 'assigns variables' do
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @group.id, :format => :json
      expect(assigns[:assignment_group]).to eql(@group)
    end
  end

  describe "POST 'create'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it 'requires authorization' do
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it 'does not allow students to create' do
      user_session(@student)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it 'creates a new group' do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :assignment_group => {:name => 'some test group'}
      expect(response).to be_redirect
      expect(assigns[:assignment_group].name).to eql('some test group')
      expect(assigns[:assignment_group].position).to eql(1)
    end

  end

  describe "PUT 'update'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    it 'requires authorization' do
      put 'update', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it 'does not allow students to update' do
      user_session(@student)
      put 'update', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it 'updates group' do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group.id, :assignment_group => {:name => 'new group name'}
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group].name).to eql('new group name')
    end
  end

  describe "DELETE 'destroy'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    it 'requires  authorization' do
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it 'does not allow students to delete' do
      user_session(@student)
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it 'deletes group' do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @group.id
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group]).not_to be_frozen
      expect(assigns[:assignment_group]).to be_deleted
    end

    it 'delete assignments in the group' do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(:name => 'group 1')
      @assignment1 = @course.assignments.create!(:title => 'assignment 1', :assignment_group => @group1)
      delete 'destroy', :course_id => @course.id, :id => @group1.id
      expect(assigns[:assignment_group]).to eql(@group1)
      expect(assigns[:assignment_group]).to be_deleted
      expect(@group1.reload.assignments.length).to eql(1)
      expect(@group1.reload.assignments[0]).to eql(@assignment1)
      expect(@group1.assignments.active.length).to eql(0)
    end

    it 'moves assignments to a different group if specified' do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(:name => 'group 1')
      @assignment1 = @course.assignments.create!(:title => 'assignment 1', :assignment_group => @group1)
      @group2 = @course.assignment_groups.create!(:name => 'group 2')
      @assignment2 = @course.assignments.create!(:title => 'assignment 2', :assignment_group => @group2)
      expect(@assignment1.position).to eql(1)
      expect(@assignment1.assignment_group_id).to eql(@group1.id)
      expect(@assignment2.position).to eql(1)
      expect(@assignment2.assignment_group_id).to eql(@group2.id)

      delete 'destroy', :course_id => @course.id, :id => @group2.id, :move_assignments_to => @group1.id

      expect(assigns[:assignment_group]).to eql(@group2)
      expect(assigns[:assignment_group]).to be_deleted
      expect(@group2.reload.assignments.length).to eql(0)
      expect(@group1.reload.assignments.length).to eql(2)
      expect(@group1.assignments.active.length).to eql(2)
      expect(@assignment1.reload.position).to eql(1)
      expect(@assignment1.assignment_group_id).to eql(@group1.id)
      expect(@assignment2.reload.position).to eql(2)
      expect(@assignment2.assignment_group_id).to eql(@group1.id)
    end

    it 'does not allow users to delete assignment groups with frozen assignments' do
      PluginSetting.stubs(:settings_for_plugin).returns(title: 'yes')
      user_session(@teacher)
      group = @course.assignment_groups.create!(name: 'group 1')
      assignment = @course.assignments.create!(
        title: 'assignment',
        assignment_group: group,
        freeze_on_copy: true
      )
      expect(assignment.position).to eq 1
      assignment.copied = true
      assignment.save!
      delete 'destroy', format: :json, course_id: @course.id, id: group.id
      expect(response).not_to be_success
    end

    it 'returns JSON if requested' do
      user_session(@teacher)
      delete 'destroy', :format => 'json', :course_id => @course.id, :id => @group.id
      expect(response).to be_success
    end
  end
end
