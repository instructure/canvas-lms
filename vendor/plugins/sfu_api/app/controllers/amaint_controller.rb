require Pathname(File.dirname(__FILE__)) + "../model/sfu/course"

class AmaintController < ApplicationController
  before_filter :require_user

  def course
    course_hash = amaint_course_info(params[:sis_id],params[:property])

    respond_to do |format|
      format.json { render :json => course_hash }
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

  # orverride ApplicationController::api_request? to force canvas to treat all calls to /sfu/api/* as an API call
  def api_request?
    true
  end
end
