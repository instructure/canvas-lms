# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

##
# Batch-loads records from a scope by their sis_source_id.
#
# TODO: update this example
# Example:
#
#    Loaders::IDLoader.for(Course).load(1).then do |course|
#      # course is Course.find_by(sis_source_id: 1)
#    end
#
class Loaders::SISIDLoader < GraphQL::Batch::Loader
  # +scope+ is any ActiveRecord scope
  def initialize(scope)
    @scope = scope
  end

  # :nodoc:
  def perform(ids)
    # Fun fact, the REST api would let you search for things based on sis_id even if you didn't have read/edit
    # permissions for SIS. For now we'll keep that behavior.
    @scope.where(sis_source_id: ids).each { |o| fulfill(o.sis_source_id, o) }

    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
