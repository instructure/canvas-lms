#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/ims/concerns/advantage_services_shared_context')
require File.expand_path(File.dirname(__FILE__) + '/ims/concerns/lti_services_shared_examples')
require_dependency "lti/public_jwk_controller"

describe Lti::DataServicesController do
  describe '#create' do
    include_context 'advantage services context'
    it_behaves_like 'lti services' do
      let(:action) { :create }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/create"}
      let(:params_overrides) do
        { developer_key: { public_jwk: {} }, account_id: root_account.id }
      end
    end
  end
end
