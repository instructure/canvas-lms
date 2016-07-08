module Factories
  class GradingPeriodGroupHelper
    TITLE = "A Title".freeze

    def create_for_enrollment_term(term)
      GradingPeriodGroup.create!(title: TITLE) do |group|
        group.enrollment_terms << term
      end
    end

    def create_for_account(account)
      legacy_create_for_account(account)
    end

    def legacy_create_for_course(course)
      create_for_course(course)
    end

    def create_for_course(course)
      # This relationship will eventually go away.
      # Please use this helper so that old associations can be easily
      # detected and removed when that time arrives
      course.grading_period_groups.create!(title: TITLE)
    end

    def legacy_create_for_account(account)
      # This is used exclusively for tests which depend on the now-invalid
      # relationship between grading period groups and accounts
      GradingPeriodGroup.create!(title: TITLE)do |group|
        group.account_id = account.id
      end
    end
  end
end
