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

class CanvasMetadatum < ActiveRecord::Base
  class MetadataArgumentError < ArgumentError; end
  # The Metadatum class is intended to be a place for storing
  # bits of state the are not really part of the canvas data itself.
  # An example of a good usecase would be processing state
  # for internal delayed operations (see AssetUserAccessLog).
  #
  # Although "Setting" or config information could be
  # stored in the table, this isn't very heavily cached
  # (intentionally, because the current use case is wanting
  # current read-and-write operations keep state for a logical
  # process).
  #
  # If you want to store something in here that is going to be
  # read-heavy, consider adding a caching path like what's in the
  # Setting class and allowing consumers to specify whether they want
  # it or not.
  self.table_name = "canvas_metadata"

  def self.get(key, default = {})
    raise MetadataArgumentError, "default payload should be a hash: #{default}" unless default.is_a?(Hash)

    object = CanvasMetadatum.where(key:).take
    (object&.payload || default).with_indifferent_access
  end

  # this payload will be stored as a jsonb document,
  # so it expects you're passing it a hash.  If we
  # have other usecases later we can relax the requirement,
  # but let's be strict as long as this is precisely what
  # we expect.
  def self.set(key, payload)
    raise MetadataArgumentError, "payload should be a hash: #{payload}" unless payload.is_a?(Hash)

    object = CanvasMetadatum.find_or_initialize_by(key:)
    object.payload = payload
    object.save!
  end
end
