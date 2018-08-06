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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

RSpec.shared_context "lti_1_3_spec_helper", shared_context: :metadata do
  let(:fallback_proxy) do
    Canvas::DynamicSettings::FallbackProxy.new({
      Lti::KeyStorage::PAST => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::PRESENT => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::FUTURE => Lti::RSAKeyPair.new.to_jwk.to_json
    })
  end

  before do
    allow(Canvas::DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end
end
