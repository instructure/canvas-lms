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
require 'builder'
require 'digest'
require 'set'
require 'zip/zip'

# Canvas Common Cartridge
module CC
end

require 'cc/cc_helper'
require 'cc/cc_exporter'
require 'cc/manifest'
require 'cc/wiki_resources'
require 'cc/module_meta'
require 'cc/learning_outcomes'
require "cc/canvas_resource"
require "cc/assignment_resources"
require "cc/topic_resources"
require "cc/web_resources"
require "cc/web_links"
require 'cc/resource'
require 'cc/organization'
require 'cc/qti/qti'
