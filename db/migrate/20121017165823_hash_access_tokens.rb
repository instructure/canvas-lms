class HashAccessTokens < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    AccessToken.find_each(:conditions => "crypted_token is null") do |at|
      at.token = at.read_attribute(:token) # regenerate as encrypted
      at.save!
    end
  end

  def self.down
    AccessToken.update_all({ :crypted_token => nil, :token_hint => nil })
  end
end
