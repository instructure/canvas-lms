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

    # save the previous definition of `destroy` and alias it to `destroy_permanently!`
    # Note: `destroy_permanently!` now does NOT throw errors while the newly defined
    # `destroy` DOES throw errors due to `save!`
    alias_method :destroy_permanently!, :destroy
    def destroy
      self.workflow_state = 'deleted'
      save!
      run_callbacks :destroy
      true
    end

    # `restore` was taken by too many other methods...
    def undestroy
      self.workflow_state = 'active'
      save!
      true
    end
  end
end
