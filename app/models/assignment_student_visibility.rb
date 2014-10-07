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
    check_args(opts, :user_id)
    vis_hash = pluck_assignment_and_user_ids(opts).group_by{|record| record["user_id"]}
    format_visibility_hash!(vis_hash,"assignment_id")
    # if users have no visibilities add their keys to the hash with an empty array
    vis_hash.reverse_merge!(empty_id_hash(opts[:user_id]))
  end

  def self.users_with_visibility_by_assignment(opts)
    check_args(opts, :assignment_id)
    vis_hash = pluck_assignment_and_user_ids(opts).group_by{|record| record["assignment_id"]}
    format_visibility_hash!(vis_hash,"user_id")
    # if assignments have no users with visibility, add their keys to the hash with an empty array
    vis_hash.reverse_merge!(empty_id_hash(opts[:assignment_id]))
  end

  def self.format_visibility_hash!(vis_hash, key_for_value)
    # pluck_assignment_and_user_ids().group_by return oddly formatted results
    # {"142"=>[{"user_id"=>"142", "assignment_id"=>"63"}]}
    # => {142=>[63]}
    vis_hash.keys.each{ |key|
      vis_hash[key.to_i] = vis_hash.delete(key).map{|v|
        v[key_for_value].to_i
      }
    }
  end

  def self.empty_id_hash(ids)
    # [1,2,3] => {1:[],2:[],3:[]}
    Hash[ids.zip(ids.map{[]})]
  end

  def self.check_args(opts, key)
    # throw error if the the right args aren't given
    [:course_id, key].each{ |k| opts.fetch(k) }
  end

  def self.pluck_assignment_and_user_ids(opts)
    # select_all allows plucking multiple columns without instantiating AR objects
    connection.select_all( self.where(opts).select([:user_id, :assignment_id]) )
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