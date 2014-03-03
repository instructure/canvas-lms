module LoggingFilter
  FILTERED_PARAMETERS = [:password, :auth_password, :access_token, :api_key, :client_secret, :fb_sig_friends]
  def self.filtered_parameters
    FILTERED_PARAMETERS
  end

  EXTENDED_FILTERED_PARAMETERS = ["pseudonym[password]", "login[password]", "pseudonym_session[password]"]
  def self.all_filtered_parameters
    FILTERED_PARAMETERS.map(&:to_s) + EXTENDED_FILTERED_PARAMETERS
  end

  def self.filter_uri(uri)
    filter_query_string(uri)
  end

  def self.filter_query_string(qs)
    regs = all_filtered_parameters.map { |p| p.gsub("[", "\\[").gsub("]", "\\]") }.join('|')
    @@filtered_parameters_regex ||= %r{([?&](?:#{regs}))=[^&]+}
    qs.gsub(@@filtered_parameters_regex, '\1=[FILTERED]')
  end

  def self.filter_params(params)
    params.each do |k,v|
      params[k] = "[FILTERED]" if all_filtered_parameters.include?(k.to_s.downcase)
      params[k] = filter_params(v) if v.is_a? Hash
    end
    params
  end
end
