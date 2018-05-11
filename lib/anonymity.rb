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

# This file contains routines for creating IDs used for graders and submission
# in place of the objects' actual IDs for Anonymous Moderated Marking.
# The IDs are 5 characters long and in base58 format. These IDs are meant to be
# unique across the graders or submissions for a given assignment: a grader
# for an assignment, for example, can be referenced by their "anonymous" ID
# for that specific assignment so that their default ID is concealed.
module Anonymity

  # Returns a unique short id to be used as an anonymous ID. If the
  # generated short id is already in use, loop until an available
  # one is generated.
  # This method will throw a unique constraint error from the
  # database if it has used all unique ids.
  # An optional argument of existing_ids can be supplied
  # to customize the handling of existing ids. E.g. bulk
  # generation of anonymous ids where you wouldn't want to
  # continuously query the database
  def self.generate_id(existing_ids: [])
    loop do
      short_id = self.generate_short_id
      break short_id unless existing_ids.include?(short_id)
    end
  end

  private_class_method

  # base58 to avoid literal problems with prefixed 0 (i.e. when 0x123
  # is interpreted as a hex value `0x123 == 291`), and similar looking
  # characters: 0/O, I/l
  def self.generate_short_id
    SecureRandom.base58(5)
  end
end
