# frozen_string_literal: true

class AddPseudonymsLowerUniqueIdIndex < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :pseudonyms, "LOWER(unique_id), account_id", name: "index_pseudonyms_on_unique_id_and_account_id", algorithm: :concurrently
  end
end
