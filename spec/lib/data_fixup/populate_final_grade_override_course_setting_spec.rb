#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateFinalGradeOverrideCourseSetting do
  let_once(:account) { Account.create! }
  let_once(:course) { Course.create!(account: account) }
  let_once(:teacher1) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let_once(:teacher2) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

  def run
    DataFixup::PopulateFinalGradeOverrideCourseSetting.run
  end

  def set_user_gradebook_setting!(user:, course:, value:)
    user.preferences.deep_merge!({
      gradebook_settings: {course.id => {"show_final_grade_overrides" => value}}
    })
    user.save!
  end

  def user_gradebook_settings(user:, course:)
    user.reload.preferences.dig(:gradebook_settings, course.id)
  end

  def course_setting(course:)
    course.reload.settings[:allow_final_grade_override]
  end

  describe ".run" do
    before(:once) { account.allow_feature!(:final_grades_override) }

    context "for a course with the Final Grade Override feature flag set to ON" do
      before(:once) { course.enable_feature!(:final_grades_override) }

      context "when the course does not have a value for the course setting" do
        it "sets the course setting to true if any instructor has the gradebook setting enabled for the course" do
          set_user_gradebook_setting!(user: teacher1, course: course, value: "true")
          set_user_gradebook_setting!(user: teacher2, course: course, value: "false")

          run
          expect(course_setting(course: course)).to eq "true"
        end
        
        it "sets the course setting to false if at least one instructor has it disabled and no one has it enabled" do
          set_user_gradebook_setting!(user: teacher1, course: course, value: "false")

          run
          expect(course_setting(course: course)).to eq "false"
        end

        it "does not set the course setting if no instructors have the gradebook setting configured for the course" do
          run
          expect(course_setting(course: course)).to be nil
        end

        it "removes the gradebook setting from instructors for the course in question" do
          set_user_gradebook_setting!(user: teacher1, course: course, value: "true")

          run
          expect(user_gradebook_settings(user: teacher1, course: course)).not_to have_key("show_final_grade_overrides")
        end

        it "does not update instructors' gradebook settings if they have not set the setting" do
          set_user_gradebook_setting!(user: teacher1, course: course, value: "true")

          expect {
            run
          }.not_to change {
            user_gradebook_settings(user: teacher2, course: course)
          }
        end
      end

      context "when the course setting is set to false" do
        it "sets the course setting to true if any instructor has the gradebook setting enabled" do
          course.update!(allow_final_grade_override: "false")
          set_user_gradebook_setting!(user: teacher1, course: course, value: "true")

          run
          expect(course_setting(course: course)).to eq "true"
        end

        it "does not modify the course setting if no instructor has set the gradebook setting" do
          course.update!(allow_final_grade_override: "false")

          expect {
            run
          }.not_to change {
            course_setting(course: course)
          }
        end
      end

      context "when the course setting is set to true" do
        it "does not modify the course setting even if an instructor has set it to false" do
          course.update!(allow_final_grade_override: "true")
          set_user_gradebook_setting!(user: teacher1, course: course, value: "false")

          expect {
            run
          }.not_to change {
            course_setting(course: course)
          }
        end
      end
    end

    context "for a course with the Final Grade Override feature flag set to OFF" do
      it "does not update the course setting" do
        expect {
          run
        }.not_to change {
          course.reload.updated_at
        }
      end

      it "does not update the preferences of instructors in the course" do
        expect {
          run
        }.not_to change {
          teacher1.reload.updated_at
        }
      end
    end

    context "for an account with final_grade_override forced to ON" do
      before(:each) do
        account.enable_feature!(:final_grades_override)
      end

      it "updates courses for which at least one instructor has the preference set to true" do
        set_user_gradebook_setting!(user: teacher1, course: course, value: "true")
        set_user_gradebook_setting!(user: teacher2, course: course, value: "false")
        run

        expect(course_setting(course: course)).to eq "true"
      end

      it "updates courses for which no instructor has the preference set to true" do
        set_user_gradebook_setting!(user: teacher1, course: course, value: "false")
        run

        expect(course_setting(course: course)).to eq "false"
      end

      it "does not update courses for which no instructor has the preference set at all" do
        run

        expect(course_setting(course: course)).to eq nil
      end

      it "updates courses in sub-accounts for which at least one instructor has the preference set to true" do
        subaccount = Account.create!(parent_account: account)
        subaccount_course = Course.create!(account: subaccount)
        subaccount_course.enroll_teacher(teacher1, enrollment_state: "active")
        set_user_gradebook_setting!(user: teacher1, course: subaccount_course, value: "true")

        run
        expect(course_setting(course: subaccount_course)).to eq "true"
      end

      it "removes the gradebook setting from instructors for courses descending from the account" do
        subaccount = Account.create!(parent_account: account)
        subaccount_course = Course.create!(account: subaccount)
        subaccount_course.enroll_teacher(teacher1, enrollment_state: "active")
        set_user_gradebook_setting!(user: teacher1, course: subaccount_course, value: "true")

        run
        expect(user_gradebook_settings(user: teacher1, course: subaccount_course)).not_to have_key("show_final_grade_overrides")
      end
    end

    context "for an account with the Final Grade Override feature flag set to ALLOW" do
      it "does not change the course setting for courses within the account" do
        account.allow_feature!(:final_grades_override)

        expect {
          run
        }.not_to change {
          course_setting(course: course)
        }
      end

      it "does not update the preferences of instructors in courses within the account" do
        expect {
          run
        }.not_to change {
          teacher1.reload.updated_at
        }
      end
    end

    context "for an account with the Final Grade Override feature flag set to OFF" do
      it "does not change the course setting for courses within the account" do
        account.disable_feature!(:final_grades_override)

        expect {
          run
        }.not_to change {
          course_setting(course: course)
        }
      end

      it "does not update the preferences of instructors in courses within the account" do
        expect {
          run
        }.not_to change {
          teacher1.reload.updated_at
        }
      end
    end
  end
end
