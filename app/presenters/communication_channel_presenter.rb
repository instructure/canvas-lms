# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class CommunicationChannelPresenter
  def initialize(communication_channel, request)
    @communication_channel = communication_channel
    @request = request
  end

  def confirmation_url
    data = @communication_channel.confirmation_url_data
    return "" if incomplete_data?(data)

    build_url(data)
  end

  private

  def incomplete_data?(data)
    data.nil? || data[:confirmation_code].nil?
  end

  def host_url(data)
    # NOTE: multiple_root_accounts plugin will override HostUrl
    HostUrl.context_host(data[:context], @request.try(:host_with_port))
  end

  def build_url(data)
    "#{HostUrl.protocol}://#{host_url(data)}/register/#{data[:confirmation_code]}"
  end
end
