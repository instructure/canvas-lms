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
#

module DuplicatingObjects
  # Lowercases title and replaces spaces with hyphens (to allow to check for
  # matching titles that differ only in case or space/hyphens)
  def normalize_title(title)
    title.gsub(/ /, '-').downcase
  end

  # Given a title, returns the first "non-conflicting" title.  "entity"
  # should provide a function "get_potentially_conflicting_titles" that
  # returns a set of titles that might conflict with the entity's title.
  #
  # If the given title ends in "#{copy_suffix} #" (or without the number),
  # tries incrementing from # (or 2 if no number is given) until one is
  # found that isn't in the set returned by entity.get_potentially_conflicting_titles
  #
  # If not, then first tries just appending copy_suffix, and if that has a
  # conflict, increments from 2 as above.
  #
  # For the purposes of matching, conflicts are case-insensitive and also
  # treats hyphens and spaces as the same thing.
  def get_copy_title(entity, copy_suffix, entity_title)
    is_multiple_copy = !(normalize_title(entity_title)=~
      /#{Regexp.quote(copy_suffix.downcase)}-[0-9]*$/).nil?
    normalized_suffix = normalize_title(copy_suffix)
    if normalize_title(entity_title).end_with?(normalized_suffix) || is_multiple_copy
      potential_title = entity_title
      possible_num_to_try = normalize_title(entity_title).scan(/\d+$/).first
      num_to_try = possible_num_to_try ? possible_num_to_try.to_i + 1 : 2
    else
      potential_title = "#{entity_title} #{copy_suffix}"
      num_to_try = 2
    end
    title_base = !is_multiple_copy ? potential_title + " " : potential_title.gsub(/\d+$/, '')
    title_search_term = title_base[0...-1]
    conflicting_titles = entity.get_potentially_conflicting_titles(title_search_term).map {
      |x| normalize_title(x)
    }
    return potential_title unless conflicting_titles.include?(normalize_title(potential_title))
    loop do
      title_attempt = "#{title_base}#{num_to_try}"
      num_to_try = num_to_try.succ
      return title_attempt unless conflicting_titles.include?(normalize_title(title_attempt))
    end
  end
end
