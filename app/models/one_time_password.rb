class OneTimePassword < ActiveRecord::Base
  belongs_to :user, inverse_of: :one_time_passwords

  validates :user_id, :code, presence: true
  before_validation :generate_code

  def generate_code
    self.code ||= SecureRandom.random_bytes(Setting.get('one_time_password_length', 8).to_i).each_byte.map do |b|
      (b % 10).to_s
    end.join
  end
end
