#
# Copyright (C) 2018 - present Instructure, Inc.
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

module GraphQLNodeLoader
  def self.load(type, id, ctx)
    check_read_permission = make_permission_check(ctx, :read)

    case type
    when "Course"
      Loaders::IDLoader.for(Course).load(id).then(check_read_permission)
    when "Assignment"
      Loaders::IDLoader.for(Assignment).load(id).then(check_read_permission)
    when "Section"
      Loaders::IDLoader.for(CourseSection).load(id).then(check_read_permission)
    when "User"
      Loaders::IDLoader.for(User).load(id).then(->(user) do
        return nil unless user && ctx[:current_user]

        return user if user.grants_right?(ctx[:current_user], :read_full_profile)

        has_permission = Rails.cache.fetch(["node_user_perm", ctx[:current_user], user].cache_key) do
          has_perm = Shard.with_each_shard(user.associated_shards & ctx[:current_user].associated_shards) do
            shared_courses = Enrollment
              .joins("INNER JOIN #{Enrollment.quoted_table_name} e2 ON e2.course_id = enrollments.course_id")
              .where("enrollments.user_id = ? AND e2.user_id = ?", user.id, ctx[:current_user].id)
              .select("enrollments.course_id")

            break true if Course.where(id: shared_courses).any? do |course|
              course.grants_right?(ctx[:current_user], :read_roster) &&
                course.enrollments_visible_to(ctx[:current_user], include_concluded: true).where(user_id: user).exists?
            end
          end
          has_perm == true
        end

        has_permission ? user : nil
      end)
    when "Enrollment"
      Loaders::IDLoader.for(Enrollment).load(id).then do |enrollment|
        Loaders::IDLoader.for(Course).load(enrollment.course_id).then do |course|
          if enrollment.user_id == ctx[:current_user].id ||
              course.grants_right?(ctx[:current_user], ctx[:session], :read_roster)
            enrollment
          else
            nil
          end
        end
      end
    when "Group"
      Loaders::IDLoader.for(Group).load(id).then(check_read_permission)
    when "GroupSet"
      Loaders::IDLoader.for(GroupCategory).load(id).then do |category|
        Loaders::AssociationLoader.for(GroupCategory, :context)
          .load(category)
          .then(check_read_permission)
      end
    when "GradingPeriod"
      Loaders::IDLoader.for(GradingPeriod).load(id).then(check_read_permission)
    when "Module"
      Loaders::IDLoader.for(ContextModule).load(id).then do |mod|
        Loaders::AssociationLoader.for(ContextModule, :context)
          .load(mod)
          .then(check_read_permission)
      end
    when "Page"
      Loaders::IDLoader.for(WikiPage).load(id).then do |page|
        # This association preload loads the requisite dependencies for
        # checking :read permission.  This might be wasted work due to
        # permissions caching???
        Loaders::AssociationLoader.for(WikiPage, wiki: [:course, :group])
          .load(page)
          .then(check_read_permission)
      end
    when "AssignmentGroup"
      Loaders::IDLoader.for(AssignmentGroup).load(id).then(check_read_permission)
    when "Discussion"
      Loaders::IDLoader.for(DiscussionTopic).load(id).then(check_read_permission)
    when "Quiz"
      Loaders::IDLoader.for(Quizzes::Quiz).load(id).then(check_read_permission)
    when "Submission"
      Loaders::IDLoader.for(Submission).load(id).then(check_read_permission)
    else
      raise UnsupportedTypeError.new("don't know how to load #{type}")
    end
  end

  def self.make_permission_check(ctx, *permissions)
    ->(o) {
      o&.grants_any_right?(ctx[:current_user], ctx[:session], *permissions) ? o : nil
    }
  end

  class UnsupportedTypeError < StandardError; end
end
