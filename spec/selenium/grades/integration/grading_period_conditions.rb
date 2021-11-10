# frozen_string_literal: true

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

shared_context 'all grading periods' do
  before(:each) do
    @grading_period_index = 0
  end
end

shared_context 'grading period one' do
  before(:each) do
    @grading_period_index = 1
  end
end

shared_context 'grading period two' do
  before(:each) do
    @grading_period_index = 2
  end
end

shared_context 'no grading periods' do
  before(:each) do
    @grading_period_index = nil
  end
end
