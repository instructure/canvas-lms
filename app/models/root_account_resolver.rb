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

module RootAccountResolver
  # Resolve the root account for this model through some available relationship.
  #
  # Pass a symbol for the relationship name whose root_account_id should be
  # inherited, or a proc to resolve from the instance manually. If your source
  # is an Account, we will use its #resolved_root_account_id helper instead.
  #
  #     resolves_root_account through: :enrollment
  #     resolves_root_account through: ->(instance) {
  #       instance.enrollment_term&.course&.root_account_id
  #     }
  #
  def resolves_root_account(through:)
    resolver = case through
    when Symbol
      ->(instance) do
        source = instance.send(through)

        case source
        when Account
          source.resolved_root_account_id
        else
          source&.root_account_id
        end
      end
    when Proc
      through
    else
      raise ArgumentError.new("Expected resolver to be a Symbol or a Proc, got #{through}")
    end

    belongs_to :root_account, class_name: 'Account'

    before_save do
      # some models might be manipulated in migrations before the column is added;
      # check that the attribute actually exists on this instance before trying to
      # populate it
      next unless attributes.key?('root_account_id')
      self.root_account_id ||= resolver[self]
    end
  end
end
