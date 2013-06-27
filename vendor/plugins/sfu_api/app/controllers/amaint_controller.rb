require Pathname(File.dirname(__FILE__)) + "../model/sfu/sfu"

class AmaintController < ApplicationController
  before_filter :require_user
  include Common

  def course_info
    course_hash = amaint_course_info(params[:sis_id], params[:property])

    raise(ActiveRecord::RecordNotFound) if course_hash.empty?

    respond_to do |format|
      format.json { render :json => course_hash }
    end
  end

  def user_info
    user_array =[]
    sfu_id = params[:sfu_id]
    if params[:property].nil?
      user_hash = {}
	    user_hash["sfu_id"] = sfu_id
      user_hash["roles"] = SFU::User.roles sfu_id
	    user_array << user_hash
    elsif params[:property].to_s.eql? "roles"
      user_array = SFU::User.roles sfu_id
    elsif params[:filter].nil? && params[:property].to_s.start_with?("term")
      user_array = teaching_terms_for sfu_id
    elsif params[:property].to_s.start_with?("term")
	    user_array = courses_for_user(sfu_id, params[:filter])
    end

    raise(ActiveRecord::RecordNotFound) if user_array.empty?

    respond_to do |format|
      format.json { render :json => user_array }
    end
  end

  def amaint_course_info(sis_id, property=nil)
    # sis_id format 1131:::math:::100:::d300:::Precalculus
    # or format 1131-math-100-d300
    sis_id.gsub!(":::","-")    
    course_hash = {}
    course_info = sis_id.split("-")
    course_hash["name"] = course_info[1]
    course_hash["number"] = course_info[2]
    course_hash["section"] = course_info[3]
    course_hash["peopleSoftCode"] = course_info.first
    course_hash["sis_source_id"] = course_hash["peopleSoftCode"] + "-" +
        course_hash["name"].downcase +  "-" +
        course_hash["number"] + "-" +
        course_hash["section"].downcase
    # If asking for a specific property then clear hash
    course_hash = {} unless property.nil?
    course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_info[1] + course_info[2], course_info.first, course_info[3]) if property.nil? || property.downcase.eql?("sectiontutorials")
    course_hash["title"] = SFU::Course.title(course_info[1] + course_info[2], course_info.first) if property.nil? || property.downcase.eql?("title")
    course_hash
  end

  def courses_for_user(sfu_id, term_code=nil)
    course_array = []
    exclude_sectionCode = ["STL", "LAB", "TUT"]

    if term_code.nil?
      courses = SFU::Course.for_instructor(sfu_id)
    else
      courses = SFU::Course.for_instructor(sfu_id, term_code)
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
          if term_code.nil?
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, course_hash["peopleSoftCode"], course_hash["section"])
          else
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, term_code, course_hash["section"])
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
    course_array
  end

  def teaching_terms_for(sfu_id)
    terms = SFU::Course.terms sfu_id
    term_array = []
    terms.each do |term|
      term_array.push term
    end
    term_array
  end

end
