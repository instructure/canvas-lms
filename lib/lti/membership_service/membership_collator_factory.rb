module Lti
  module MembershipService
    class MembershipCollatorFactory
      class << self
        def collator_instance(context, user, opts)
          if context.is_a?(Course) && opts[:role].present? && opts[:role].include?(IMS::LIS::ContextType::URNs::Group)
            return Lti::MembershipService::CourseGroupCollator.new(context, opts)
          end
          Lti::MembershipService::LisPersonCollator.new(context, user, opts)
        end
      end
    end
  end
end
