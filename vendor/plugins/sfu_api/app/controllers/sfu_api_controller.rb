class SfuApiController < ApplicationController

  def course
    sis_id = params[:sis_id]
    course = Course.where(:sis_source_id => sis_id).all
    course_hash = {}
    if course.length == 1
      course_hash["id"] = course.first.id
      course_hash["name"] = course.first.name
      course_hash["course_code"] = course.first.course_code
      course_hash["sis_source_id"] = course.first.sis_source_id
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
      user_hash["id"] = user.id
      user_hash["name"] = user.name
      user_hash["uuid"] = user.uuid
      user_hash["login_id"] = pseudonym.first.unique_id
      user_hash["sis_user_id"] = pseudonym.first.sis_user_id
    end

    respond_to do |format|
      format.json { render :text => user_hash.to_json }
    end
  end

end
