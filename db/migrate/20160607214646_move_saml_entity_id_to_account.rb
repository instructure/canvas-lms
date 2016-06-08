class MoveSamlEntityIdToAccount < ActiveRecord::Migration
  tag :postdeploy

  def up
    AccountAuthorizationConfig::SAML.active.where.not(entity_id: nil).each do |ap|
      ap.account.settings[:saml_entity_id] ||= ap.entity_id
      ap.account.save!
    end
  end
end
