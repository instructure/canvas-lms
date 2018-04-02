#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'object_view'

describe ObjectView do
  let(:text) { "Example\n{ \"id\": 5 } { \"start_date\": \"2012-01-01\" }" }
  let(:view) { ObjectView.new(double('Element', :text => text)) }

  it "separates json into parts" do
    expect(view.clean_json_text_parts).to eq(
      ["\n{ \"id\": 5 }", "{ \"start_date\": \"2012-01-01\" }"]
    )
  end
end
