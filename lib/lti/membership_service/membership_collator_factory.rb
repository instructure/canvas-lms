module Lti
  module MembershipService
    class MembershipCollatorFactory
      class << self
        def collator_instance(context, user, opts)
          if context.is_a?(Course)
            if opts[:role].present? && opts[:role].include?(IMS::LIS::ContextType::URNs::Group)
              Lti::MembershipService::CourseGroupCollator.new(context, opts)
            else
              Lti::MembershipService::CourseLisPersonCollator.new(context, user, opts)
            end
          else
            Lti::MembershipService::GroupLisPersonCollator.new(context, user, opts)
          end
        end
      end
    end
  end
end
