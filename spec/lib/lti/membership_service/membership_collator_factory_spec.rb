#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Lti::MembershipService
  describe MembershipCollatorFactory do
    before(:each) do
      course_with_teacher
    end

    describe '.collator_instance' do
      it 'returns and LisPersonCollator instance by default' do
        collator = MembershipCollatorFactory.collator_instance(@course, @teacher, {})
        expect(collator.class).to eq Lti::MembershipService::LisPersonCollator
      end
    end
  end
end
