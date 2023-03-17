# frozen_string_literal: true

class SingleSignOnRecord < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :external_id, uniqueness: true
end
