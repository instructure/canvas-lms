module VisibilityPluckingHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def visible_object_ids_in_course_by_user(column_to_pluck, opts)
      use_global_id = opts.delete(:use_global_id)
      check_args(opts, :user_id)
      vis_hash = {}
      pluck_own_and_user_ids(column_to_pluck, opts).each do |user_id, column_val|
        user_id = Shard.global_id_for(user_id) if use_global_id
        vis_hash[user_id] ||= []
        vis_hash[user_id] << column_val
      end
      # if users have no visibilities add their keys to the hash with an empty array
      vis_hash.reverse_merge!(empty_id_hash(opts[:user_id]))
    end

    def users_with_visibility_by_object_id(column_to_pluck, opts)
      check_args(opts, column_to_pluck)
      vis_hash = {}
      pluck_own_and_user_ids(column_to_pluck, opts).each do |user_id, column_val|
        vis_hash[column_val] ||= []
        vis_hash[column_val] << user_id
      end

      # if assignment/quiz has no users with visibility, add their keys to the hash with an empty array
      vis_hash.reverse_merge!(empty_id_hash(opts[column_to_pluck]))
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
      self.where(opts).pluck(:user_id, column_to_pluck)
    end
  end
end