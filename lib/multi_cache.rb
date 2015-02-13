#
# Copyright (C) 2014 Instructure, Inc.
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

module MultiCache
  def self.copies(key)
    [Setting.get("#{key}_copies", 1).to_i, 1].max
  end

  def self.fetch(key, options = nil, &block)
    options ||= {}
    Rails.cache.fetch("#{key}:#{rand(options[:copies] || copies(key))}", options, &block)
  end

  def self.delete(key, options = nil)
    options ||= {}
    (0...(options[:copies] || copies(key))).each do |i|
      Rails.cache.delete("#{key}:#{i}", options)
    end
  end
end
