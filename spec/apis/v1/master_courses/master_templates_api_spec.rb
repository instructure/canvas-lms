require_relative '../../api_spec_helper'

describe MasterCourses::MasterTemplatesController, type: :request do
  def setup_template
    Account.default.enable_feature!(:master_courses)
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    account_admin_user(:active_all => true)
    @base_params = {:controller => 'master_courses/master_templates', :format => 'json',
      :course_id => @course.id.to_s, :template_id => 'default'}
  end

  describe "#show" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default"
      @params = @base_params.merge(:action => 'show')
    end

    it "should require the feature flag" do
      Account.default.disable_feature!(:master_courses)
      api_call(:get, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should require authorization" do
      Account.default.role_overrides.create!(:role => admin_role, :permission => "manage_master_courses", :enabled => false)
      api_call(:get, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should require am active template" do
      @template.destroy!
      api_call(:get, @url, @params, {}, {}, {:expected_status => 404})
    end

    it "should return stuff" do
      time = 2.days.ago
      @template.master_migrations.create!(:imports_completed_at => time, :workflow_state => 'completed')
      json = api_call(:get, @url, @params)
      expect(json['id']).to eq @template.id
      expect(json['course_id']).to eq @course.id
      expect(json['last_export_completed_at']).to eq time.iso8601
    end
  end

  describe "#associated_courses" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/associated_courses"
      @params = @base_params.merge(:action => 'associated_courses')
    end

    it "should get some data for associated courses" do
      term = Account.default.enrollment_terms.create!(:name => "termname")
      child_course1 = course_factory(:course_name => "immachildcourse1", :active_all => true)
      @teacher.update_attribute(:short_name, "displayname")
      child_course1.update_attributes(:sis_source_id => "sisid", :course_code => "shortname", :enrollment_term => term)
      child_course2 = course_factory(:course_name => "immachildcourse2")
      [child_course1, child_course2].each{|c| @template.add_child_course!(c)}

      json = api_call(:get, @url, @params)
      expect(json.count).to eq 2
      expect(json.map{|c| c['id']}).to match_array([child_course1.id, child_course2.id])
      course1_json = json.detect{|c| c['id'] == child_course1.id}
      expect(course1_json['name']).to eq child_course1.name
      expect(course1_json['course_code']).to eq child_course1.course_code
      expect(course1_json['term_name']).to eq term.name
      expect(course1_json['teachers'].first['display_name']).to eq @teacher.short_name
    end
  end

  describe "#update_associations" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/update_associations"
      @params = @base_params.merge(:action => 'update_associations')
    end

    it "should only add courses in the blueprint courses' account (or sub-accounts)" do
      sub1 = Account.default.sub_accounts.create!
      sub2 = Account.default.sub_accounts.create!
      @course.update_attribute(:account, sub1)

      other_course = course_factory(:account => sub2)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("invalid courses")
    end

    it "should not try to add other blueprint courses" do
      other_course = course_factory
      MasterCourses::MasterTemplate.set_as_master_course(other_course)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("invalid courses")
    end

    it "should not try to add other blueprint-associated courses" do
      other_master_course = course_factory
      other_template = MasterCourses::MasterTemplate.set_as_master_course(other_master_course)
      other_course = course_factory
      other_template.add_child_course!(other_course)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("cannot add courses already associated")
    end

    it "should skip existing associations" do
      other_course = course_factory
      @template.add_child_course!(other_course)

      @template.any_instantiation.expects(:add_child_course!).never
      api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]})
    end

    it "should be able to add and remove courses" do
      existing_child = course_factory
      existing_sub = @template.add_child_course!(existing_child)

      subaccount1 = Account.default.sub_accounts.create!
      subaccount2 = subaccount1.sub_accounts.create!
      c1 = course_factory(:account => subaccount1)
      c2 = course_factory(:account => subaccount2)

      api_call(:put, @url, @params, {:course_ids_to_add => [c1.id, c2.id], :course_ids_to_remove => existing_child.id})

      @template.reload
      expect(@template.child_subscriptions.active.pluck(:child_course_id)).to match_array([c1.id, c2.id])
    end
  end
end
