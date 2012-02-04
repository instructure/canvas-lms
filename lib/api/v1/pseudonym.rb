module Api::V1::Pseudonym
  include Api::V1::Json

  API_PSEUDONYM_JSON_OPTS = [:id, :user_id, :account_id, :unique_id, :sis_user_id]

  def pseudonym_json(pseudonym, current_user, session)
    api_json(pseudonym, current_user, session, :only => API_PSEUDONYM_JSON_OPTS)
  end
end

