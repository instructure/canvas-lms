module Lti
  module MembershipService
    class MembershipCollatorFactory
      class << self
        def collator_instance(context, user, opts)
          collator_class(opts).new(context, user, opts)
        end

        private

        def collator_class(opts)
          Lti::MembershipService::LisPersonCollator
        end
      end
    end
  end
end
