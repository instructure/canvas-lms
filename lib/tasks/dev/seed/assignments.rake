namespace :dev do
  namespace :seed do
    desc 'Seed a Course with an Assignment with overrides and a selection of users'
    task :assignments_with_overrides, [:course_id, :assignment_count, :starting_assignment_idx, :starting_user_id, :user_count] => :environment do |t, args|
      # Param Description
      # course_id is the id field of the Course record
      # assignment_count is the number of assignments you'd like to create
      # starting_user_id is the id field of the first User record enrolled in this Course
      # user_count is the number of users to limit this Assignment to

      course = Course.find(args.fetch(:course_id))
      assignment_count = args.fetch(:assignment_count, '0').to_i
      starting_assignment_idx = args.fetch(:starting_assignment_idx, '0').to_i
      starting_user_id = args.fetch(:starting_user_id, '0').to_i
      user_count = args.fetch(:user_count, '0').to_i
      initial_due_date = (user_count / 2).days.ago

      matching_users = User.where('id >= ?', starting_user_id).order(id: :asc).limit(user_count)

      ActiveRecord::Base.transaction do
        (starting_assignment_idx...(starting_assignment_idx + assignment_count)).each do |assignment_idx|
          due_date = initial_due_date

          assignment_attrs = {
            name: "Assignment ##{assignment_idx}",
            points_possible: 10.0,
          }

          puts "Creating #{assignment_attrs[:name]}"
          assignment = course.assignments.create!(assignment_attrs)

          assignment_override_attrs = {
            workflow_state: 'active',
            due_at_overridden: true,
          }

          matching_users.each do |user|
            puts "  Adding Assignment Override for #{user.name} due at #{due_date}"

            overridden_attrs = {
              due_at: due_date,
              title: "Override for #{user.id} - #{user.name}"
            }

            assignment_override = assignment.assignment_overrides.create!(assignment_override_attrs.merge(overridden_attrs))
            assignment_override.assignment_override_students.create!(assignment: assignment, user: user)

            due_date += 1.day
          end
        end
      end
    end
  end
end