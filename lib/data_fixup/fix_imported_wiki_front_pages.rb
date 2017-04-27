#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup::FixImportedWikiFrontPages
  # some Wiki objects are getting has_no_front_page set to true, even when there should be a front page
  def self.potentially_broken_wikis
    Wiki.where(:has_no_front_page => true)
  end

  def self.run
    self.potentially_broken_wikis.find_in_batches do |wikis|
      Wiki.where(:id => wikis).update_all(:has_no_front_page => nil)
    end
  end
end
