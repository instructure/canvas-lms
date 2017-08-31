module Courses
  module ItemVisibilityHelper
    ITEM_TYPES = [:assignment, :discussion, :page, :quiz].freeze

    def visible_item_ids_for_users(item_type, user_ids)
      # return all the item ids that are visible to _any_ of the users
      raise "unknown item type" unless ITEM_TYPES.include?(item_type)
      cache_visibilities_for_users(item_type, user_ids)
      user_ids.flat_map{|user_id| @cached_visibilities[item_type][user_id]}.uniq
    end

    def cache_item_visibilities_for_user_ids(user_ids)
      ITEM_TYPES.each do |item_type|
        cache_visibilities_for_users(item_type, user_ids)
      end
    end

    def clear_cached_item_visibilities
      @cached_visibilities&.clear
    end

    private

    def cache_visibilities_for_users(item_type, user_ids)
      @cached_visibilities ||= {}
      @cached_visibilities[item_type] ||= {}
      missing_user_ids = user_ids - @cached_visibilities[item_type].keys
      return unless missing_user_ids.any?

      visibilities = get_visibilities_for_user_ids(item_type, missing_user_ids)
      missing_user_ids.each do |user_id|
        @cached_visibilities[item_type][user_id] = visibilities[user_id] || []
      end
    end

    def get_visibilities_for_user_ids(item_type, user_ids)
      opts = {user_id: user_ids, course_id: [self.id]}
      case item_type
      when :assignment
        AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(opts)
      when :discussion
        DiscussionTopic.visible_ids_by_user(opts)
      when :page
        WikiPage.visible_ids_by_user(opts)
      when :quiz
        Quizzes::QuizStudentVisibility.visible_quiz_ids_in_course_by_user(opts)
      end
    end
  end
end
