# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
