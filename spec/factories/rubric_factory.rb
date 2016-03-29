#
# Copyright (C) 2011 Instructure, Inc.
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

def rubric_model(opts={})
  @rubric = factory_with_protected_attributes(Rubric, valid_rubric_attributes.merge(opts))
end

def valid_rubric_attributes
  {
    :context => Account.default,
    :title => "test rubric",
    :data => [{
      :description => "Some criterion",
      :points => 10,
      :id => 'crit1',
      :ratings => [
        {:description => "Good", :points => 10, :id => 'rat1', :criterion_id => 'crit1'},
        {:description => "Medium", :points => 5, :id => 'rat2', :criterion_id => 'crit1'},
        {:description => "Bad", :points => 0, :id => 'rat3', :criterion_id => 'crit1'}
      ]
    }]
  }
end

def larger_rubric_data
  [
    { :description => "Crit1", :points => 10, :id => 'crit1',
      :ratings => [
        { :description => "A", :points => 10, :id => 'rat1', :criterion_id => 'crit1' },
        { :description => "B", :points => 7, :id => 'rat2', :criterion_id => 'crit1' },
        { :description => "F", :points => 0, :id => 'rat3', :criterion_id => 'crit1' }] },

    { :description => "Crit2", :points => 2, :id => 'crit2',
      :ratings => [
        { :description => "Pass", :points => 2, :id => 'rat1', :criterion_id => 'crit2' },
        { :description => "Fail", :points => 0, :id => 'rat2', :criterion_id => 'crit2' }] },
  ]
end

def rubric_for_course
  @rubric = Rubric.new(:title => 'My Rubric', :context => @course)
  @rubric.data = [
      {
          :points => 3,
          :description => "First row",
          :long_description => "The first row in the rubric",
          :id => 1,
          :ratings => [
              {
                  :points => 3,
                  :description => "Rockin'",
                  :criterion_id => 1,
                  :id => 2
              },
              {
                  :points => 2,
                  :description => "Rockin'",
                  :criterion_id => 1,
                  :id => 3
              },
              {
                  :points => 0,
                  :description => "Lame",
                  :criterion_id => 1,
                  :id => 4
              }
          ]
      }
  ]
  @rubric.save!
end
