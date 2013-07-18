class TermController < ApplicationController

  # get current term
  def current_term
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (:date BETWEEN start_at AND end_at) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}]).first
  end

  # get next n term(s)
  def next_terms(num_terms=1)
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (start_at > :date) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}], :order => "sis_source_id", :limit => num_terms)
  end

  # get prev n term(s)
  def prev_terms(num_terms=1)
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (end_at < :date) AND (sis_source_id IS NOT NULL)", {:date => DateTime.now}], :order => "sis_source_id DESC", :limit => num_terms)
  end

end