# frozen_string_literal: true

class PopulateRootAccountIdOnUserObservers < ActiveRecord::Migration[5.0]
  tag :predeploy

  def up
    DataFixup::PopulateRootAccountIdOnUserObservers.run
  end

  def down
  end
end
