module Factories
  class GradingPeriodGroupHelper
    TITLE = "Example Grading Period Group".freeze

    def valid_attributes(attr = {})
      {
        title: TITLE
      }.merge(attr)
    end

    def create_for_account(account)
      account.grading_period_groups.create!(title: TITLE)
    end

    def legacy_create_for_course(course)
      # This relationship will eventually go away.
      # Please use this helper so that old associations can be easily
      # detected and removed when that time arrives
      course.grading_period_groups.create!(title: TITLE)
    end
  end
end
