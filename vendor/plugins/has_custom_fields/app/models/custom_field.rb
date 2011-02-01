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

class CustomField < ActiveRecord::Base
  has_many :custom_field_values, :dependent => :destroy

  validates_inclusion_of :field_type, :in => %w(boolean)

  validates_uniqueness_of :name, :scope => %w(scoper_type scoper_id target_type)

  belongs_to :scoper, :polymorphic => true

  named_scope :for_class, lambda { |klass|
    { :conditions => { :target_type => klass.name.underscore.pluralize } }
  }
end
