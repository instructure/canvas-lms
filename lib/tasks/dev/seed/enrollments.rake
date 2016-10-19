namespace :dev do
  namespace :seed do
    desc 'Seed a course with a given number of enrollments by auto-generated users'
    task :enrollments, [:course_id, :starting_user_id, :user_count] => :environment do |t, args|
      # Param Description
      # course_id is the id field of the Course record
      # starting_user_id is the id field of the User record
      # user_count is the number of users to limit this Course's enrollment to

      course = Course.find(args.fetch(:course_id))

      starting_user_id = args.fetch(:starting_user_id, '0').to_i
      user_count = args.fetch(:user_count, '0').to_i

      ActiveRecord::Base.transaction do
        matching_users = User.where('id >= ?', starting_user_id).order(id: :asc).limit(user_count)

        puts "Enrolling #{matching_users.size} users into #{course.name}"

        already_enrolled_users = StudentEnrollment.where(course: course).where(user: matching_users)
        puts "  Not re-enrolling #{already_enrolled_users.size} already enrolled users"

        final_matching_users = matching_users.where.not(id: already_enrolled_users.map(&:user_id))

        final_matching_users.each do |u|
          puts "  Enrolling #{u.name}"
          course.enroll_user(u, 'StudentEnrollment').accept!
        end
      end
    end
  end
end