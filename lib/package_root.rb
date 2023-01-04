# frozen_string_literal: true

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

class PackageRoot
  # initialize with the root directory of an extracted package
  def initialize(root_path)
    @root_path = Pathname(root_path).realpath
    @prefix = @root_path.to_s + "/"
  end

  # return the root path. NOTE: don't manually File.join this; use item_path instead
  def root_path
    @root_path.to_s
  end

  # return the absolute path of an item in the package, given one or more relative path entries
  # e.g., if the root_path is /tmp/blah and args are ['foo', 'bar'], returns "/tmp/blah/foo/bar"
  # raises an error if ".." path entries would traverse above the root_path in the file system.
  def item_path(*relative_path_entries)
    path = Pathname(File.join(@prefix, *relative_path_entries)).cleanpath.to_s
    raise ArgumentError, "invalid relative_path_entries: #{relative_path_entries.inspect}" unless path.start_with?(@prefix)

    path
  end

  # given a full path to an item in the package, return its path relative to the package root
  def relative_path(item_path)
    Pathname(item_path).realpath.relative_path_from(@root_path).to_s
  end

  # enumerate files matching the given pattern
  def contents(pattern = "**/*")
    Dir[@root_path.join(pattern).to_s]
  end
end
