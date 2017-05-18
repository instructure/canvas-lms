#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'compiled/editor/stocktiny'
  'tinymce_plugins/instructure_image/plugin'
  'tinymce_plugins/instructure_links/plugin'
  'tinymce_plugins/instructure_embed/plugin'
  'tinymce_plugins/instructure_equation/plugin'
  'tinymce_plugins/instructure_equella/plugin'
  'tinymce_plugins/instructure_external_tools/plugin'
  'tinymce_plugins/instructure_record/plugin'
], (tinymce) ->

  tinymce
