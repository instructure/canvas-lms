class TermController < ApplicationController


  # get all terms
  def all_terms
    ActiveRecord::Base.include_root_in_json = false
    t = EnrollmentTerm.find(:all, :select => select_fields, :conditions => ["workflow_state = 'active' AND (root_account_id = 2)"])
    respond_to do |format|
      format.json {render :json => t}
    end
    ActiveRecord::Base.include_root_in_json = true
  end

  # get specific term by sis id
  def term_by_sis_id
    ActiveRecord::Base.include_root_in_json = false
    t = EnrollmentTerm.find(:all, :select => select_fields, :conditions => ["workflow_state = 'active' AND (root_account_id = 2) AND (sis_source_id = '#{params[:sis_id]}')"])
    respond_to do |format|
      format.json {render :json => t}
    end
    ActiveRecord::Base.include_root_in_json = true
  end

  # get current term
  def current_term
    ActiveRecord::Base.include_root_in_json = false
    t = EnrollmentTerm.find(:all, :select => select_fields, :conditions => ["workflow_state = 'active' AND (root_account_id = 2) AND (:date BETWEEN start_at AND end_at) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}]).first
    respond_to do |format|
      format.json {render :json => t}
    end
    ActiveRecord::Base.include_root_in_json = true
  end

  # get next n term(s)
  def next_terms
    ActiveRecord::Base.include_root_in_json = false
    t = EnrollmentTerm.find(:all, :select => select_fields, :conditions => ["workflow_state = 'active' AND (start_at > :date) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}], :order => "sis_source_id", :limit => params[:num_terms])
    respond_to do |format|
      format.json {render :json => t}
    end
    ActiveRecord::Base.include_root_in_json = true
  end

  # get prev n term(s)
  def prev_terms(num_terms=1)
    ActiveRecord::Base.include_root_in_json = false
    t = EnrollmentTerm.find(:all, :select => select_fields, :conditions => ["workflow_state = 'active' AND (end_at < :date) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}], :order => "sis_source_id DESC", :limit => params[:num_terms])
    respond_to do |format|
      format.json {render :json => t}
    end
    ActiveRecord::Base.include_root_in_json = true
  end

  private
  def select_fields
    "name, sis_source_id, start_at, end_at"
  end

end