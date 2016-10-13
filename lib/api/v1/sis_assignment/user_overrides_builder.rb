# "user_overrides": [
#   {
#     "id": 163,
#     "name": "Test McTest",
#     "sis_user_id": "123-456",
#     "override": {
#       "due_at": "2016-08-29T05:59:59Z"
#      }
#   },
#   {
#     "id": [
#       {
#         "id": 5,
#         "name": "Bob",
#         "sis_user_id": "84746"
#       },
#       {
#         "id": 7,
#         "name": "Joe",
#         "sis_user_id": "29361"
#       }
#     ],
#     "override": {
#       "due_at": "2016-08-28T05:59:59Z"
#     }
#   },
#
#   ...
#
# ]
class Api::V1::SisAssignment::UserOverridesBuilder
  include Api::V1::Json

  USER_LEVEL_JSON_OPTS = {
    only: %i(id name sis_user_id).freeze
  }.freeze

  USER_LEVEL_OVERRIDES_JSON_OPTS = {
    only: %i(assignment_override_id due_at).freeze
  }.freeze

  def initialize(assignment, json)
    @assignment = assignment
    @json       = json
  end

  def update_json
    users = active_user_level_assignment_overrides
    return if users.nil?
    @json.merge!(user_overrides: sis_assignment_users_json(users))
  end

  private

  def active_user_level_assignment_overrides
    if @assignment.assignment_override_students.present?
      @assignment.assignment_override_students
    end
  end

  def sis_assignment_users_json(users)
    users = extract_multiple_user_overrides(users)
    users.map { |s| sis_assignment_user_json(s) }
  end

  # Deals with a case where the same assignment override
  # is assigned to more than one student.
  def extract_multiple_user_overrides(user_overrides)
    matching_pairs = []

    override_info = user_overrides.map do |user|
     Api::V1::SisAssignment::UserOverride.new(user)
    end

    info_copy = override_info
    override_info.each do |override|
      info_copy.each do |copy|
        if override.id != copy.id && override.override_id == copy.override_id
          matching_pairs.push([override.id, copy.id].sort())
        end
      end
    end

    pairs = get_unique_pairs(matching_pairs)
    return user_overrides if pairs.nil?
    get_associated_user_info(user_overrides, pairs)
  end

  def get_unique_pairs(matching_pairs)
    found_pairs = []

    pairs = matching_pairs.map do |numbers|
      pair = numbers.uniq - found_pairs
      found_pairs += pair
      pair
    end

    pairs.reject!(&:empty?)
  end

  def get_associated_user_info(users, unique_pairs)
    overrides = active_assignment_overrides
    associated_users = []
    valid_user_overrides = users.to_a
    unique_pairs.each do |pair|
      if pair.class == Array
        temp = []
        temp_due_at = nil
        pair.each do |id|
          user = users.find(id)
          temp_due_at = overrides.find(user.assignment_override_id).due_at
          temp.push({'id' => user.user_id,
                     'name' => user.user.name,
                     'sis_user_id' => user.user.pseudonym.sis_user_id}) if user && id == user.id
          valid_user_overrides.delete_if { |u| u.id == id }
        end
        temp.push({'due_at' => temp_due_at})
        associated_users.push(temp)
      else
        user = users.find(pair)
        if user && pair == user.id
          associated_users << {
            'id' => user.user_id,
            'name' => user.user.name,
            'sis_user_id' => user.user.pseudonym.sis_user_id
          }
        end

        valid_user_overrides.delete_if { |u| u.id == pair }
      end
    end

    associated_users.concat(valid_user_overrides)
  end

  def active_assignment_overrides
    if @assignment.association(:active_assignment_overrides).loaded?
      @assignment.active_assignment_overrides
    elsif @assignment.association(:assignment_overrides).loaded?
      @assignment.assignment_overrides.select(&:active?)
    end
  end

  def sis_assignment_user_json(user)
    if user.class == Array
      json = {}
      *json[:id], json[:override] = user
    else
      # This merge! is required so we can obtain the name from the user object
      # and the rest of the attributes from the pseudonym object
      sis_assignment_user_level_json      = api_json(user.user,           nil, nil, USER_LEVEL_JSON_OPTS)
      sis_assignment_pseudonym_level_json = api_json(user.user.pseudonym, nil, nil, USER_LEVEL_JSON_OPTS)
      json = sis_assignment_user_level_json.merge!(sis_assignment_pseudonym_level_json)
      add_sis_assignment_user_level_override_json(json, user)
    end
    json
  end


  def add_sis_assignment_user_level_override_json(json, user)
    assignment_overrides = active_assignment_overrides
    return unless assignment_overrides

    override = assignment_overrides.detect do |assignment_override|
      assignment_override.set_type == 'ADHOC' &&
      assignment_override.assignment_id == user.assignment_id &&
      assignment_override.id == user.assignment_override_id
    end

    return if override.nil?

    override_json = api_json(override, nil, nil, USER_LEVEL_OVERRIDES_JSON_OPTS)
    json[:override] = override_json
  end
end

