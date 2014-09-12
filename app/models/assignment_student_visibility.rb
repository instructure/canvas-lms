class AssignmentStudentVisibility < ActiveRecord::Base
  # necessary for general_model_spec
  attr_protected :user, :assignment, :course

  belongs_to :user
  belongs_to :assignment
  belongs_to :course

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.visible_assignment_ids_in_course_by_user(opts)
    return {} unless opts.try(:[], :course_id)
    vis_hash = pluck_assignment_and_user_ids(opts).group_by{|record| record["user_id"]}
    vis_hash.keys.each{ |key|
      vis_hash[key.to_i] = vis_hash.delete(key).map{|v|
        v["assignment_id"].to_i
      }
    }
    vis_hash
  end

  def self.users_with_visibility_by_assignment(opts)
    return {} unless opts.try(:[], :course_id)
    vis_hash = pluck_assignment_and_user_ids(opts).group_by{|record| record["assignment_id"]}
    vis_hash.keys.each{ |key|
      vis_hash[key.to_i] = vis_hash.delete(key).map{|v|
        v["user_id"].to_i
      }
    }
    vis_hash
  end

  def self.pluck_assignment_and_user_ids(opts)
    # select_all allows plucking multiplecolumns without instantiating AR objects
    connection.select_all( self.where(opts).select([:user_id, :assignment_id]) )
  end

  def self.visible_assignment_ids_for_user(user_id, course_ids=nil)
    opts = {user_id: user_id}
    if course_ids
      opts[:course_id] = course_ids
    end
    self.where(opts).pluck(:assignment_id)
  end

  def self.filter_for_differentiated_assignments(collection, user, context, opts={}, &filter)
    return collection if !user || context.grants_any_right?(user, :manage_content, :read_as_admin, :manage_grades, :manage_assignments)
    return filter.call(collection, [user.id]) unless context.user_has_been_observer?(user)

    observed_student_ids = opts[:observed_student_ids] || ObserverEnrollment.observed_student_ids(context, user)
    user_ids = [user.id].concat(observed_student_ids)
    # if observer is following no students, do not filter based on differentiated assignments
    observed_student_ids.any? ? filter.call(collection, user_ids) : collection
  end

  # readonly? is not checked in destroy though
  before_destroy { |record| raise ActiveRecord::ReadOnlyRecord }
end