# frozen_string_literal: true

#
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

module AccountDomainSpecHelper
  # Stubs Account#environment_specific_domain to return the specified domain.
  def stub_host_for_environment_specific_domain(host)
    # can't mock environment_specific_domain directly on
    # any_instance due to it being overridden in MRA, so mock this
    # which works as long as test_cluster_name is nil
    allow(HostUrl).to receive_messages(context_host: host, default_host: host)
  end
end
