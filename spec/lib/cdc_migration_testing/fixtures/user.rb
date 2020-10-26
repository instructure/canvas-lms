# frozen_string_literal: true

module CdcFixtures
  def self.create_user
    User.create(name: 'CDC Sample User')
  end
end
