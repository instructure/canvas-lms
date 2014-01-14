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
require 'zip'

# Canvas Common Cartridge
module CC
end

require_dependency 'cc/cc_helper'
require_dependency 'cc/cc_exporter'
require_dependency 'cc/manifest'
require_dependency 'cc/wiki_resources'
require_dependency 'cc/module_meta'
require_dependency 'cc/learning_outcomes'
require_dependency "cc/canvas_resource"
require_dependency "cc/assignment_resources"
require_dependency "cc/events"
require_dependency "cc/topic_resources"
require_dependency "cc/web_resources"
require_dependency "cc/web_links"
require_dependency 'cc/resource'
require_dependency 'cc/organization'
require_dependency 'cc/qti/qti'
require_dependency 'cc/importer'
