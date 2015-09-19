#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Lti
  describe ResourcePlacement do

    describe 'validations' do

      it 'requires a resource_handler' do
        subject.save
        expect(subject.errors.first).to eq [:message_handler, "can't be blank"]
      end

      it 'accepts types in PLACEMENT_LOOKUP' do
        subject.placement = ResourcePlacement::PLACEMENT_LOOKUP.values.first
        subject.save
        expect(subject.errors).to_not include(:placement)
      end

    end

  end
end