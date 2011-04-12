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

require 'canvas/plugin'
require 'cc/importer/cc_worker'
Rails.configuration.to_prepare do
  Canvas::Plugin.register :common_cartridge_importer, :export_system, {
          :name => 'Common Cartridge Importer',
          :author => 'Instructurecon',
          :description => 'This enables converting a canvas CC export to the intermediary json format to be imported',
          :version => '1.0.0',
          :settings => {
                  :worker=>'CCWorker',
                  :migration_partial => 'cc_config',
                  :select_text => "Canvas Course Export (.imscc)"
          }
  }
end