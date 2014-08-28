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
    # select_all allows plucking columns without instantiating AR objects
    vis_hash = connection.select_all( self.where(opts).select([:user_id, :assignment_id]) ).group_by{|r| r["user_id"]}
    # map strings to ints in both the keys and values
    vis_hash.keys.each{ |key|
      vis_hash[key.to_i] = vis_hash.delete(key).map{|v|
        v["assignment_id"].to_i
      }
    }
    vis_hash
  end

  def self.visible_assignment_ids_for_user(user_id, course_ids=nil)
    opts = {user_id: user_id}
    if course_ids
      opts[:course_id] = course_ids
    end
    self.where(opts).pluck(:assignment_id)
  end

  # readonly? is not checked in destroy though
  before_destroy { |record| raise ActiveRecord::ReadOnlyRecord }
end