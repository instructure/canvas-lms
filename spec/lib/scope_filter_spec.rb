#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe ScopeFilter do
  let_once(:current_course) { course_factory }
  let_once(:current_user) { course_factory.all_real_users.first }
  let_once(:scope_filter) { ScopeFilter.new(current_course, current_user) }
  describe '#initialize' do
    it 'should set instance vars' do
      expect(scope_filter.context).to eq(current_course)
      expect(scope_filter.user).to eq(current_user)
    end

    describe '#concat_scope' do
      it 'should set @relation as value returned from provided block' do
        scope_filter.send(:concat_scope) { Course.all }
        expect(scope_filter.instance_variable_get("@relation")).to eq(Course.all)
      end

      it 'should maintain @relation when block returns a falsey value' do
        scope_filter.send(:concat_scope) { Course.all }
        expect(scope_filter.instance_variable_get("@relation")).to eq(Course.all), 'precondition'
        scope_filter.send(:concat_scope) { nil }
        expect(scope_filter.instance_variable_get("@relation")).to eq(Course.all)
      end
    end
  end
end
