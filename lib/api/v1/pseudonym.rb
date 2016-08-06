module Api::V1::Pseudonym
  include Api::V1::Json

  API_PSEUDONYM_JSON_OPTS = [:id,
                             :user_id,
                             :account_id,
                             :unique_id,
                             :sis_user_id,
                             :integration_id,
                             :authentication_provider_id].freeze

  def pseudonym_json(pseudonym, current_user, session)
    opts = API_PSEUDONYM_JSON_OPTS
    opts = opts.reject { |opt| [:sis_user_id, :integration_id].include?(opt) } unless pseudonym.account.grants_any_right?(current_user, :read_sis, :manage_sis)
    api_json(pseudonym, current_user, session, :only => opts).tap do |result|
      if pseudonym.authentication_provider
        result[:authentication_provider_type] = pseudonym.authentication_provider.auth_type
      end
    end
  end

  def pseudonyms_json(pseudonyms, current_user, session)
    ActiveRecord::Associations::Preloader.new.preload(pseudonyms, :authentication_provider)
    pseudonyms.map do |p|
      pseudonym_json(p, current_user, session)
    end
  end
end
