class AddRedirectUrisToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :developer_keys, :redirect_uris, :string, array: true, default: [], null: false

    DeveloperKey.all.find_each do |dk|
      next unless dk.redirect_uri
      dk.redirect_uris = [dk.redirect_uri]
      dk.save!
    end
  end
end
