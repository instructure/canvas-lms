class Api::V1::SisAssignment::UserOverride
  attr_reader :id, :user_id, :override_id

  def initialize(user)
    @id          = user.id
    @user_id     = user.user_id
    @override_id = user.assignment_override_id
  end
end

