module VisibilityPluckingHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def visible_object_ids_in_course_by_user(column_to_pluck, opts)
      check_args(opts, :user_id)
      vis_hash = pluck_own_and_user_ids(column_to_pluck, opts).group_by{|record| record["user_id"]}
      format_visibility_hash!(vis_hash, column_to_pluck.to_s)
      # if users have no visibilit ies add their keys to the hash with an empty array
      vis_hash.reverse_merge!(empty_id_hash(opts[:user_id]))
    end

    def users_with_visibility_by_object_id(column_to_pluck, opts)
      check_args(opts, column_to_pluck)
      vis_hash = pluck_own_and_user_ids(column_to_pluck, opts).group_by{|record| record[column_to_pluck.to_s]}
      format_visibility_hash!(vis_hash,"user_id")
      # if assignment/quiz has no users with visibility, add their keys to the hash with an empty array
      vis_hash.reverse_merge!(empty_id_hash(opts[column_to_pluck]))
    end

    def format_visibility_hash!(vis_hash, key_for_value)
      # pluck_own_and_user_ids().group_by return oddly formatted results
      # {"142"=>[{"user_id"=>"142", "assignment_id"=>"63"}]} ((or "quiz_id"))
      # => {142=>[63]}
      vis_hash.keys.each{ |key|
        vis_hash[key.to_i] = vis_hash.delete(key).map{|v|
          v[key_for_value].to_i
        }
      }
    end

    def empty_id_hash(ids)
      # [1,2,3] => {1:[],2:[],3:[]}
      Hash[ids.zip(ids.map{[]})]
    end

    def check_args(opts, key)
      # throw error if the the right args aren't given
      [:course_id, key].each{ |k| opts.fetch(k) }
    end

    def pluck_own_and_user_ids(column_to_pluck, opts)
      # select_all allows plucking multiple columns without instantiating AR objects
      connection.select_all( self.where(opts).select([:user_id, column_to_pluck]) )
    end
  end
end