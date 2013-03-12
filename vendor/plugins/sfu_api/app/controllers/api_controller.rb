#require "rest_client"
#require "json"
require Pathname(File.dirname(__FILE__)) + "../model/sfu/course"

class ApiController < ApplicationController
  before_filter :require_user

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
      format.json { render :text => course_hash.to_json }
    end
  end

  def user
    account_id = Account.find_by_name('Simon Fraser University').id
    sfu_id = params[:sfu_id]
    pseudonym = Pseudonym.where(:unique_id => sfu_id, :account_id => account_id).all
    user_hash = {}
    unless pseudonym.empty?
      user = User.find pseudonym.first.user_id
      if params[:property].nil?
        user_hash["id"] = user.id
        user_hash["name"] = user.name
        user_hash["uuid"] = user.uuid
      elsif params[:property].eql? "uuid"
        user_hash = user.uuid
      elsif params[:property].eql? "terms"
        user_hash = teaching_terms_for sfu_id
      end
    end

    respond_to do |format|
      format.json { render :text => user_hash.to_json }
    end
  end

  def courses
    course_array = []

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
            course_hash["sectionTutorials"] = section_tutorials_for(course_code, course_hash["peopleSoftCode"], course_hash["section"])
          else
            course_hash["sectionTutorials"] = section_tutorials_for(course_code, params[:term], course_hash["section"])
          end
        end

        course_hash["key"] = course_hash["peopleSoftCode"] + ":::" +
                             course_hash["name"].downcase +  ":::" +
                             course_hash["number"] + ":::" +
                             course_hash["section"].downcase + ":::" +
                             course_hash["title"]
        course_hash["key"].concat ":::" + course_hash["sectionTutorials"].downcase.delete(" ") unless course_hash["sectionTutorials"].empty?

        # hide course if already exists in Canvas or is a Tutorial/Lab
        course_array.push course_hash unless course_exists? course_hash["sis_source_id"] unless c["course"].first["sectionCode"].to_s == "STL" unless c["course"].first["sectionCode"].to_s == "LAB"
      end
    end

    respond_to do |format|
      format.json { render :text => course_array.to_json }
    end
  end

  def course_info(sis_id, property = nil)
    course = Course.where(:sis_source_id => sis_id).all
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

  def course_exists?(sis_source_id)
    course = Course.where(:sis_source_id => sis_source_id).all
    if course.length == 1
      return true
    end
    false
  end

  def teaching_terms_for(sfu_id)
    terms = SFU::Course.terms sfu_id
    term_array = []
    terms.each do |term|
      term_array.push term
    end
    term_array
  end

  def section_tutorials_for(course_code, term_code, section_code)
    details = SFU::Course.info course_code, term_code
    main_section = section_code[0..2].downcase
    sections = ""

    unless details == "[]"
      details.each do |info|
        code = info["course"]["name"] + info["course"]["number"]
        section = info["course"]["section"].downcase
        if code.downcase == course_code.downcase && section.start_with?(main_section) && section.downcase != section_code.downcase
          sections += info["course"]["section"] + ", "
        end
      end
    end
    sections[0..-3]
  end
end
