require 'active_support/concern'

module Canvas::SoftDeletable
  extend ActiveSupport::Concern

  included do
    include Workflow

    workflow do
      state :active
      state :deleted
    end

    scope :active, -> { where workflow_state: "active" }

    # save the previous definition of `destroy` and alias it to `destroy!`
    # Note: `destroy!` now does NOT throw errors while the newly defined
    # `destroy` DOES throw errors due to `save!`
    alias_method :destroy!, :destroy
    def destroy
      self.workflow_state = 'deleted'
      save!
      run_callbacks :destroy
    end
  end
end
