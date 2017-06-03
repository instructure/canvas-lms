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

require 'mocha/api'

module MochaRspecAdapter
  include Mocha::API
  include ::RSpec::Mocks::ExampleMethods

  # rspec-mocks shadows mocha's implementations of kind_of, instance_of, and
  # anything. if you need those, please use rspec-mocks syntax

  def setup_mocks_for_rspec
    mocha_setup
    ::RSpec::Mocks.setup
  end

  def verify_mocks_for_rspec
    mocha_verify
    ::RSpec::Mocks.verify
  end

  def teardown_mocks_for_rspec
    mocha_teardown
    ::RSpec::Mocks.teardown
  end
end

RSpec.configure do |config|
  config.mock_with MochaRspecAdapter
end
