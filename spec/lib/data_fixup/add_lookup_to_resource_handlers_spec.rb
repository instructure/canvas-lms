#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require 'db/migrate/20170508171328_change_lti_resouce_handler_lookup_id_not_null.rb'
require 'spec_helper'

describe DataFixup::AddLookupToResourceHandlers do
  include_context 'lti2_spec_helper'

  let(:mig_change_lookup_id) { ChangeLtiResouceHandlerLookupIdNotNull.new }

  it 'sets the the lookup_id on existing resource handlers' do
    mig_change_lookup_id.migrate(:down)
    resource_handler.update_attribute(:lookup_id, nil)
    mig_change_lookup_id.migrate(:up)
    expected_id = Lti::ResourceHandler.generate_lookup_id_for(resource_handler)
    expected_id = expected_id.rpartition('-').first
    expect(resource_handler.reload.lookup_id.rpartition('-').first).to eq expected_id
  end
end
