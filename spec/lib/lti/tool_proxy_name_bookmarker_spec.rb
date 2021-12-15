# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../lti_spec_helper"
require_relative "name_bookmarker_base_shared_examples"

describe Lti::ToolProxyNameBookmarker do
  include_context "name_bookmarker_base_shared_examples"

  include LtiSpecHelper

  it_behaves_like "a bookmarker for models with names", order: true do
    let(:model_factory_proc) do
      ->(account, model_name) { create_tool_proxy(context: account, name: model_name) }
    end

    let(:model_base_scope) { Lti::ToolProxy }
  end
end
