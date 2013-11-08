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

# Assocates a rubric with an "association", or idea.  An assignment, for example.
# RubricAssessments, then, are concrete assessments of the artifacts associated
# with this idea, such as assignment submissions.
# The other purpose of this class is just to make rubrics reusable.
class RubricAssociation < ActiveRecord::Base
  attr_accessor :skip_updating_points_possible
  attr_accessible :rubric, :association, :context, :use_for_grading, :title, :description, :summary_data, :purpose, :url, :hide_score_total, :bookmarked
  belongs_to :rubric
  belongs_to :association, :polymorphic => true

  belongs_to :context, :polymorphic => true
  has_many :rubric_assessments, :dependent => :nullify
  has_many :assessment_requests, :dependent => :destroy
  
  has_a_broadcast_policy

  validates_presence_of :purpose, :rubric_id, :association_id, :association_type, :context_id, :context_type
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

  before_save :update_assignment_points
  before_save :update_values
  after_create :update_rubric
  after_create :link_to_assessments
  before_save :update_old_rubric
  after_destroy :update_rubric
  after_destroy :update_alignments
  after_save :assert_uniqueness
  after_save :update_alignments
  serialize :summary_data

  ValidAssociationModels = {
    'Course' => ::Course,
    'Assignment' => ::Assignment,
    'Account' => ::Account,
  }

  # takes params[:association_type] and params[:association_id] and finds the
  # valid association object, if possible. Valid types are listed in
  # ValidAssociationModels. This doesn't verify the user has access to the
  # object.
  def self.get_association_object(params)
    return nil unless params
    a_type = params.delete(:association_type)
    a_id = params.delete(:association_id)
    return @context if a_type == @context.class.to_s && a_id == @context.id
    klass = ValidAssociationModels[a_type]
    return nil unless klass
    klass.find_by_id(a_id) if a_id.present? # authorization is checked in the calling method
  end

  set_broadcast_policy do |p|
    p.dispatch :rubric_association_created
    p.to { self.context.students rescue [] }
    p.whenever {|record|
      record.just_created && !record.context.is_a?(Course)
    }
  end
  
  scope :bookmarked, where(:bookmarked => true)
  scope :for_purpose, lambda { |purpose| where(:purpose => purpose) }
  scope :for_grading, where(:purpose => 'grading')
  scope :for_context_codes, lambda { |codes| where(:context_code => codes) }
  scope :include_rubric, includes(:rubric)
  scope :before, lambda { |date| where("rubric_associations.created_at<?", date) }

  def assert_uniqueness
    if purpose == 'grading'
      RubricAssociation.find_all_by_association_id_and_association_type_and_purpose(association_id, association_type, 'grading').each do |ra|
        ra.destroy unless ra == self
      end
    end
  end
  
  def assignment
    if self.association.is_a?(Assignment)
      self.association
    else
      nil
    end
  end

  def update_alignments
    return unless assignment
    outcome_ids = []
    unless self.destroyed?
      outcome_ids = rubric.learning_outcome_alignments.map(&:learning_outcome_id)
    end
    LearningOutcome.update_alignments(assignment, context, outcome_ids)
    true
  end
  
  def update_old_rubric
    if self.rubric_id_changed? && self.rubric_id_was && self.rubric_id_was != self.rubric_id
      rubric = Rubric.find(self.rubric_id_was)
      rubric.destroy if rubric.rubric_associations.count == 0 && rubric.rubric_assessments.count == 0
    end
  end
  
  def context_name
    @cached_context_name ||= Rails.cache.fetch(['short_name_lookup', self.context_code].cache_key) do
      self.context.short_name rescue ""
    end
  end
  
  def update_values
    self.bookmarked = true if self.purpose == 'bookmark' || self.bookmarked.nil?
    self.context_code ||= "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.title ||= (self.association.title rescue self.association.name) rescue nil
  end
  protected :update_values
  
  attr_accessor :assessing_user_id

  set_policy do
    given {|user, session| self.cached_context_grants_right?(user, session, :manage) }
    can :update and can :delete and can :manage and can :assess
    
    given {|user, session| user && @assessing_user_id && self.assessment_requests.for_assessee(@assessing_user_id).map{|r| r.assessor_id}.include?(user.id) }
    can :assess
    
    given {|user, session| self.cached_context_grants_right?(user, session, :participate_as_student) }
    can :submit
  end
  
  def update_assignment_points
    if self.use_for_grading && !self.skip_updating_points_possible && self.association && self.association.respond_to?(:points_possible=) && self.rubric && self.rubric.points_possible && self.association.points_possible != self.rubric.points_possible
      self.association.update_attribute(:points_possible, self.rubric.points_possible) 
    end
  end
  protected :update_assignment_points

  def remind_user(assessee)
    assessment_request = self.assessment_requests.find_by_user_id(assessee.id)
    assessment_request ||= self.assessment_requests.build(:user => assessee)
    assessment_request.send_reminder! if assessment_request.assigned?
    assessment_request
  end
  
  def update_rubric
    cnt = self.rubric.rubric_associations.for_grading.length rescue 0
    if self.rubric
      self.rubric.with_versioning(false) do
        self.rubric.read_only = cnt > 1
        self.rubric.association_count = cnt
        self.rubric.save

        self.rubric.destroy if cnt == 0 && self.rubric.rubric_associations.count == 0 && !self.rubric.public
      end
    end
  end
  protected :update_rubric

  # Link the rubric association to any existing assessment_requests (i.e. peer-reviews) that haven't been completed and
  # aren't currently linked to a rubric association. This routine is needed when an assignment is completed and
  # submissions were already sent when peer-review links and a *then* a rubric is created.
  def link_to_assessments
    # Go up to the assignment and loop through all submissions.
    # Update each submission's assessment_requests with a link to this rubric association
    # but only if not already associated and the assessment is incomplete.
    if self.association_id && self.association_type != 'Account'
      self.association.submissions.each do |sub|
        sub.assessment_requests.incomplete.where(:rubric_association_id => nil).
            update_all(:rubric_association_id => self)
      end
    end
  end
  protected :link_to_assessments

  def unsubmitted_users
    self.context.students - self.rubric_assessments.map{|a| a.user} - self.assessment_requests.map{|a| a.user}
  end
  
  def self.generate(current_user, rubric, context, params)
    raise "context required" unless context
    association_object = params.delete :association
    if (association_id = params.delete(:id)) && association_id.present?
      association = RubricAssociation.find_by_id(association_id)
    end
    association = nil unless association && association.context == context && association.association == association_object
    raise "association required" unless association || association_object
    # Update/create the association -- this is what ties the rubric to an entity
    update_if_existing = params.delete(:update_if_existing)
    association ||= rubric.associate_with(association_object, context, :use_for_grading => params[:use_for_grading] == "1", :purpose => params[:purpose], :update_if_existing => update_if_existing)
    association.rubric = rubric
    association.context = context
    association.skip_updating_points_possible = params.delete :skip_updating_points_possible
    association.update_attributes(params)
    association.association = association_object
    association
  end
  
  def assessments_unique_per_asset?(assessment_type)
    self.association.is_a?(Assignment) && self.purpose == "grading" && assessment_type == "grading"
  end

  def assess(opts={})
    # TODO: what if this is for a group assignment?  Seems like it should
    # give all students for the group assignment the same rubric assessment
    # results.
    association = self
    params = opts[:assessment]
    raise "User required for assessing" unless opts[:user]
    raise "Assessor required for assessing" unless opts[:assessor]
    raise "Artifact required for assessing" unless opts[:artifact]
    raise "Assessment type required for assessing" unless params[:assessment_type]
    
    if self.association.is_a?(Assignment) && !self.association.grade_group_students_individually
      students_to_assess = self.association.group_students(opts[:artifact].user).last
      artifacts_to_assess = students_to_assess.map do |student| 
        self.association.find_asset_for_assessment(self, student).first 
      end
    else
      artifacts_to_assess = [opts[:artifact]]
    end
    
    ratings = []
    score = 0
    replace_ratings = false
    self.rubric.criteria_object.each do |criterion|
      data = params["criterion_#{criterion.id}".to_sym]
      rating = {}
      if data
        replace_ratings = true
        rating[:points] = [criterion.points, data[:points].to_f].min || 0
        rating[:criterion_id] = criterion.id
        rating[:learning_outcome_id] = criterion.learning_outcome_id
        if criterion.ignore_for_scoring
          rating[:ignore_for_scoring] = true
        else
          score += rating[:points]
        end
        rating[:description] = data[:description]
        rating[:comments_enabled] = true
        rating[:comments] = data[:comments]
        rating[:above_threshold] = rating[:points] > criterion.mastery_points if criterion.mastery_points && rating[:points]
        cached_description = nil
        criterion.ratings.each do |r|
          if r.points.to_f == rating[:points].to_f
            cached_description = r.description
            rating[:id] = r.id
          end
        end
        if !rating[:description] || rating[:description].empty?
          rating[:description] = cached_description
        end
        if rating[:comments] && !rating[:comments].empty? && data[:save_comment] == '1'
          self.summary_data ||= {}
          self.summary_data[:saved_comments] ||= {}
          self.summary_data[:saved_comments][criterion.id.to_s] ||= []
          self.summary_data[:saved_comments][criterion.id.to_s] << rating[:comments]
          # TODO i18n
          self.summary_data[:saved_comments][criterion.id.to_s] = self.summary_data[:saved_comments][criterion.id.to_s].select{|desc| desc && !desc.empty? && desc != "No Details"}.uniq.sort
          self.save
        end
        rating[:description] = t('no_details', "No details") if !rating[:description] || rating[:description].empty?
        ratings << rating
      end
    end
    assessment_to_return = nil
    artifacts_to_assess.each do |artifact|
      assessment = nil
      if assessments_unique_per_asset?(params[:assessment_type])
        # Unless it's for grading, in which case assessments are unique per artifact (the assessor can change, depending on if the teacher/TA updates it)
        assessment = association.rubric_assessments.find_by_artifact_id_and_artifact_type_and_assessment_type(artifact.id, artifact.class.to_s, params[:assessment_type]) 
      else
        # Assessments are unique per artifact/assessor/assessment_type.
        assessment = association.rubric_assessments.find_by_artifact_id_and_artifact_type_and_assessor_id_and_assessment_type(artifact.id, artifact.class.to_s, opts[:assessor].id, params[:assessment_type])
      end
      assessment ||= association.rubric_assessments.build(:assessor => opts[:assessor], :artifact => artifact, :user => artifact.user, :rubric => self.rubric, :assessment_type => params[:assessment_type])
      assessment.score = score if replace_ratings
      assessment.data = ratings if replace_ratings
      assessment.comments = params[:comments] if params[:comments]

      assessment.save
      assessment_to_return = assessment if assessment.artifact == opts[:artifact]
    end
    assessment_to_return
  end
end
