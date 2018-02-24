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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OutcomeImport, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:context) }
    it { is_expected.to belong_to(:attachment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:outcome_import_errors) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :context_type }
    it { is_expected.to validate_presence_of :context_id }
  end
end
