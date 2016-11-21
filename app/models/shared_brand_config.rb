class SharedBrandConfig < ActiveRecord::Base
  belongs_to :brand_config, foreign_key: "brand_config_md5"
  belongs_to :account

  validates :brand_config, presence: true

  attr_accessible :name, :account_id, :brand_config_md5

  set_policy do
    given { |user, session| self.account.grants_right?(user, session, :manage_account_settings) }
    can :create and can :update and can :delete
  end
end
