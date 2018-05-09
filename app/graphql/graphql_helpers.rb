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

module GraphQLHelpers
  # this function allows an argument to take ids in the graphql global form or
  # standard canvas ids. the resolve function for fields using this preparer
  # will get a standard canvas id
  def self.relay_or_legacy_id_prepare_func(expected_type)
    Proc.new do |relay_or_legacy_id, ctx|
      begin
        self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
      rescue InvalidIDError => e
        GraphQL::ExecutionError.new(e.message)
      end
    end
  end

  def self.relay_or_legacy_ids_prepare_func(expected_type)
    Proc.new do |relay_or_legacy_ids, ctx|
      begin
        relay_or_legacy_ids.map { |relay_or_legacy_id, ctx|
          self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
        }
      rescue InvalidIDError => e
        GraphQL::ExecutionError.new(e.message)
      end
    end
  end

  def self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
    if relay_or_legacy_id =~ /\A\d+\Z/
      relay_or_legacy_id
    else
      type, id = GraphQL::Schema::UniqueWithinType.decode(relay_or_legacy_id)
      if (type != expected_type || id.nil?)
        raise InvalidIDError.new("expected an id for #{expected_type}")
      else
        id
      end
    end
  end

  # TODO - move this into LockType after we switch to the class-based api
  def self.make_lock_resolver(attr)
    ->(lock, _, _) {
      lock == false ?
        nil :
        lock[attr]
    }
  end

  class InvalidIDError < StandardError; end
end
