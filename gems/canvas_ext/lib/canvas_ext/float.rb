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

class Float
  # pass me a number and if it is something like 1.0 i will give you back "1" (but 1.1 stays as "1.1")
  def to_s_with_round_whole
    begin
      if !self.nan? && self.to_i == self
        self.to_i.to_s
      else
        self.to_s_without_round_whole
      end
    rescue
      self.to_s_without_round_whole
    end
  end

  alias_method :to_s_without_round_whole, :to_s
  alias_method :to_s, :to_s_with_round_whole
end