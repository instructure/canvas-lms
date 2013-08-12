module Api::V1::Pseudonym
  include Api::V1::Json

  API_PSEUDONYM_JSON_OPTS = [:id, :user_id, :account_id, :unique_id, :sis_user_id]

  def pseudonym_json(pseudonym, current_user, session)
    opts = API_PSEUDONYM_JSON_OPTS
    opts = opts.reject { |opt| opt == :sis_user_id } unless pseudonym.account.grants_rights?(current_user, :read_sis, :manage_sis).values.any?
    api_json(pseudonym, current_user, session, :only => opts)
  end

  def pseudonyms_json(pseudonyms, current_user, session)
    pseudonyms.map{ |p| pseudonym_json(p, current_user, session) }
  end
end

