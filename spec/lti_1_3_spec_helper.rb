# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "lti_1_3_tool_configuration_spec_helper"

RSpec.shared_context "lti_1_3_spec_helper", shared_context: :metadata do
  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:fallback_proxy) do
    DynamicSettings::FallbackProxy.new({
                                         CanvasSecurity::KeyStorage::PAST => CanvasSecurity::KeyStorage.new_key,
                                         CanvasSecurity::KeyStorage::PRESENT => CanvasSecurity::KeyStorage.new_key,
                                         CanvasSecurity::KeyStorage::FUTURE => CanvasSecurity::KeyStorage.new_key
                                       })
  end

  let(:developer_key) do
    dev_key_model_1_3(account:, settings: settings.merge(public_jwk: tool_config_public_jwk))
  end

  before do
    # CanvasSecurity::KeyStorage#consul_proxy calls kv_proxy and memoizes the
    # result. We need to clear the instance variable to ensure the fallback
    # proxy is used and avoid non-determintistic spec failures (e.g. "no 'sign'
    # method for nil")
    SecurityController.key_storages_by_path.each_value do |key_storage|
      key_storage.instance_variable_set(:@consul_proxy, nil)
    end
    allow(DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end
end
