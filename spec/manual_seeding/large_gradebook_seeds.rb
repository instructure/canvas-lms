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
# with this program. If not, see <http://www.gnu.org/licenses/>

require 'faker'
require 'colorize'

# Dependency:
#  Create Gemfile.d/gradebook_seed_gemfile.rb
#  add this to gradebook_seed_gemfile.rb:
#       group :development do
#         gem 'faker', '1.8.7'
#       end
#
# Usage:
# rails runner spec/manual_seeding/large_gradebook_seeds.rb
# OR
# docker-compose run --rm web rails runner spec/manual_seeding/large_gradebook_seeds.rb

# if you need to add a ton of students + assignments and you have UNIQUE
# set to true, you'll get an error because faker runs out of unique content to
# give you. So, in those cases, you can turn unique off and it'll generate course
# content for you, but some of the content will have duplicate names.
ACCOUNT = Account.default

class Theme
  def initialize(unique)
    @mapping = [
      { name: Faker::Zelda, course: :game, user: :character, assignment: :item },
      { name: Faker::Pokemon, course: :location, user: :name, assignment: :move },
      { name: Faker::Beer, course: :yeast, user: :name, assignment: :hop }
    ].sample
    @unique_content = unique
  end

  def mapping_name
    @unique_content ? @mapping[:name].unique : @mapping[:name]
  end

  def assignment
    mapping_name.send(@mapping[:assignment])
  end

  def course
    mapping_name.send(@mapping[:course])
  end

  def description
    @unique_content ? Faker::Company.unique.bs : Faker::Company.bs
  end

  def user
    mapping_name.send(@mapping[:user])
  end
end

module CreateHelpers
  def self.create_user(theme)
    user = User.create!(name: theme.user)
    puts "creating '#{user.name}'".blue
    user.pseudonyms.create!({
      unique_id: Faker::Number.number(10),
      account: ACCOUNT,
      require_password: false,
      workflow_state: 'active'
    })
    user
  end

  def self.create_users(theme:, count: 1)
    (1..count).map do
      create_user(theme)
    end
  end

  def self.create_course(name: 'CS 101', teacher:, account: ACCOUNT)
    course = account.courses.create!(name: name, workflow_state: 'available')
    puts "creating course: '#{course.name}', id: #{course.id}, account: #{account.name}".red
    puts "taught by: '#{teacher.name}', id: #{teacher.id}".green
    course.enroll_teacher(teacher, enrollment_state: 'active', workflow_state: 'available')
    course
  end

  def self.enroll_students(users: [], course:, section:, type: 'student')
    users.each do |user|
      course.enroll_student(user, section: section, allow_multiple_enrollments: true, enrollment_state: 'active')
      puts "Enrolling '#{user&.name}' as a #{type} in '#{course&.name}' - 'Section #{section&.name}'".blue
    end
  end
end

# =========================== End Function Definitions =========================
Faker::UniqueGenerator.clear

generate_for = :speedgrader
opts = OptionParser.new
opts.on('-g', '--gradebook', 'generate data for gradebook') do
  generate_for = :gradebook
end
opts.on_tail('-h', '--help', 'Show this message') do
  puts opts
  exit
end
opts.parse(ARGV)
student_count = generate_for == :speedgrader ? 50 : 400
assignment_count = generate_for == :speedgrader ? 50 : 200

puts generate_for == :speedgrader ? "Speedgrader".yellow : "Gradebook".yellow
puts "Student Count = #{student_count}".red
puts "Assignment Count = #{assignment_count}".red

theme = Theme.new(generate_for == :speedgrader)

teacher = CreateHelpers.create_user(theme)
teacher.transaction do
  teacher.workflow_state = 'registered'
  teacher.save!

  course = CreateHelpers.create_course name: theme.course, teacher: teacher, account: ACCOUNT
  students = CreateHelpers.create_users theme: theme, count: student_count

  CreateHelpers.enroll_students users: students, course: course, section: course.course_sections.first

  due_ats = [1.year.ago, 8.months.ago, 2.months.ago, 1.month.from_now, 5.months.from_now]
  assignment_count.times do
    new_title = theme.assignment
    course.assignments.create!(
      title: new_title,
      due_at: due_ats.sample,
      description: theme.description,
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10
    )
    puts "creating assignment: '#{new_title}'".green
  end

  Faker::UniqueGenerator.clear
  puts "Done!"
end
