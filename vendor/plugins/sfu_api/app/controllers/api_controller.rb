require Pathname(File.dirname(__FILE__)) + "../model/sfu/sfu"

class ApiController < ApplicationController
  before_filter :require_user
  include Common

  def course
    sis_id = params[:sis_id]
    property = params[:property]
    course_hash = {}
    if property.nil?
      course_hash = course_info sis_id
    elsif property.eql? "id"
      course_hash = course_info sis_id, "id"
    end

    respond_to do |format|
      format.json { render :json => course_hash }
    end
  end

  def user
    account_id = Account.find_by_name('Simon Fraser University').id
    sfu_id = params[:sfu_id]
    pseudonym = Pseudonym.where(:unique_id => sfu_id, :account_id => account_id).all
    
    raise(ActiveRecord::RecordNotFound) if pseudonym.empty?
    
    user_hash = {}
    unless pseudonym.empty?
      user = User.find pseudonym.first.user_id
      if params[:property].nil?
        if user.nil?
	        raise(ActiveRecord::RecordNotFound)
	      else
	        user_hash["exists"] = "true"
	      end
      elsif params[:property].eql? "profile"
        user_hash["id"] = user.id
        user_hash["name"] = user.name
        user_hash["uuid"] = user.uuid
      elsif params[:property].eql? "mysfu"
        user_hash = mysfu_enrollments_for user
      elsif params[:property].eql? "sandbox"
        user_hash = sandbox_for(user)
      end
    end

    if params[:property].to_s.eql? "profile"
      return unless authorized_action(user, @current_user, :read)
    end

    respond_to do |format|
      format.json { render :json => user_hash }
    end
  end

  def terms
    term_arr = []
    if params[:term].nil?
      terms = Account.find_by_name('Simon Fraser University').enrollment_terms.find(:all, :conditions => "workflow_state = 'active'", :order => 'sis_source_id DESC').delete_if {|t| t.name == 'Default Term'}
      terms.each do |term|
        term_info = {}
        term_info["name"] = term.name
        term_info["sis_source_id"] = term.sis_source_id
        term_info["start_at"] = term.start_at
        term_info["end_at"] = term.end_at
        term_arr.push term_info
      end
    else
      term = Account.find_by_name('Simon Fraser University').enrollment_terms.find(:all, :conditions => "sis_source_id = '#{params[:term]}'")
      term_info = {}
      term_info["name"] = term.first.name
      term_info["sis_source_id"] = term.first.sis_source_id
      term_info["start_at"] = term.first.start_at
      term_info["end_at"] = term.first.end_at
      term_arr.push term_info
    end

    raise(ActiveRecord::RecordNotFound) if term_arr.empty?

    respond_to do |format|
      format.json { render :json => term_arr }
    end

  end

  # Deprecated. Moved to amaint_controller
  def courses
    course_array = []
    exclude_sectionCode = ["STL", "LAB", "TUT"]

    if params[:term].nil?
      courses = SFU::Course.for_instructor params[:sfuid]
    else
      courses = SFU::Course.for_instructor params[:sfuid], params[:term]
    end

    courses.compact.each do |course|
      course.compact.each do |c|
        course_hash = {}
        course_hash["name"] = c["course"].first["name"]
        course_hash["title"] = c["course"].first["title"]
        course_hash["number"] = c["course"].first["number"]
        course_hash["section"] = c["course"].first["section"]
        course_hash["peopleSoftCode"] = c["course"].first["peopleSoftCode"].to_s
        course_hash["sis_source_id"] = course_hash["peopleSoftCode"] + "-" +
                                       course_hash["name"].downcase +  "-" +
                                       course_hash["number"] + "-" +
                                       course_hash["section"].downcase
        course_hash["sectionTutorials"] = ""
        course_hash["sectionCode"] = c["course"].first["sectionCode"]

        course_code = course_hash["name"]+course_hash["number"]

        if course_hash["section"].end_with? "00"
          if params[:term].nil?
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, course_hash["peopleSoftCode"], course_hash["section"])
          else
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, params[:term], course_hash["section"])
          end
        end

        course_hash["key"] = course_hash["peopleSoftCode"] + ":::" +
                             course_hash["name"].downcase +  ":::" +
                             course_hash["number"] + ":::" +
                             course_hash["section"].downcase + ":::" +
                             course_hash["title"]
        course_hash["key"].concat ":::" + course_hash["sectionTutorials"].downcase.delete(" ") unless course_hash["sectionTutorials"].empty?

        # hide course if already exists in Canvas or is a Tutorial/Lab
        course_array.push course_hash unless course_exists? course_hash["sis_source_id"] unless exclude_sectionCode.include? c["course"].first["sectionCode"].to_s
      end
    end

    respond_to do |format|
      format.json { render :json => course_array }
    end
  end

  def course_info(sis_id, property = nil)
    course = Course.where(:sis_source_id => sis_id.downcase).all
    if course.empty?
      raise(ActiveRecord::RecordNotFound)
    end
    course_hash = {}
    if course.length == 1
      if property.nil?
        course_hash["id"] = course.first.id
        course_hash["name"] = course.first.name
        course_hash["course_code"] = course.first.course_code
      elsif property.eql? "id"
        course_hash = course.first.id
      end
    end
    course_hash
  end

  # Deprecated. Moved to amaint_controller
  def teaching_terms_for(sfu_id)
    terms = SFU::Course.terms sfu_id
    term_array = []
    terms.each do |term|
      term_array.push term
    end
    term_array
  end

  def mysfu_enrollments_for(user)
    output = {
      "enrolled" => [],
      "teaching" => []
    }
    enrollment_type_map = {
      "StudentEnrollment" => "enrolled",
      "TeacherEnrollment" => "teaching",
      "TaEnrollment"      => "teaching"
    }
    enrollments = user.enrollments.with_each_shard { |scope| scope.scoped(:conditions => "enrollments.workflow_state<>'deleted' AND courses.workflow_state<>'deleted'", :include => [{:course => { :enrollment_term => :enrollment_dates_overrides }}, :associated_user, :course_section]) }
    enrollments.sort_by! {|e| e.course.enrollment_term_id }
    enrollments.each do |e|
      sis_source_id = e.course.sis_source_id
      course_id = e.course.id
      term = e.enrollment_term.sis_source_id
      enrollment_type = e.type
      status = e.course.workflow_state
      unless term.nil? || sis_source_id.nil?
        if enrollment_type_map.has_key? enrollment_type
          enrollment_type = enrollment_type_map[enrollment_type]
          course = {
            "term" => term,
            "course_sis_source_id" => sis_source_id,
            "course_id" => course_id,
            "status" => status
          }
          output[enrollment_type].push course
        end
      end
    end
    output
  end

  def sandbox_for(user)
    # Find user's courses with sis_source_id that starts with 'sandbox'
    courses = Course.find(:all, :conditions => ['id IN (?) AND sis_source_id LIKE ?', user.course_ids, 'sandbox%'])
    courses.map do |course|
      {
        :id => course.id,
        :name => course.name,
        :sis_source_id => course.sis_source_id
      }
    end
  end

  def course_enrollment
    enrollment_id = params[:enrollment_id]
    new_section_id = params[:new_section_id]
    results = { :result => "Invalid POST parameters" }
    unless enrollment_id.nil? || new_section_id.nil?
      out = Enrollment.where(:id => enrollment_id).update_all("course_section_id = #{new_section_id}")
      if out == 1
        results = { :result => "Success" }
      else
        raise "Error updating enrollment_id of '#{enrollment_id}'"
      end
    end

    respond_to do |format|
      format.json { render :json => results }
    end
  end

  def undelete_group_membership
    membership = GroupMembership.find(params[:id])
    membership.workflow_state = 'accepted'
    if membership.save
      render :json => membership.as_json(:include_root => false, :only => %w(id group_id user_id workflow_state moderator))
    else
      render :json => membership.errors, :status => :bad_request
    end
  end
end
