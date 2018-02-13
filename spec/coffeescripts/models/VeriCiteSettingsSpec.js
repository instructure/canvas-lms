#
# Copyright (C) 2016 - present Instructure, Inc.
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

define  [
  'compiled/models/VeriCiteSettings'
], ( VeriCiteSettings ) ->

  QUnit.module "VeriCiteSettings"

  QUnit.module "VeriCiteSettings#constructor"

  test "assigns originalityReportVisibility", ->
    ts = new VeriCiteSettings originality_report_visibility: 'after_grading'
    strictEqual ts.originalityReportVisibility, 'after_grading'

  test "assigns excludeQuoted", ->
    ts = new VeriCiteSettings exclude_quoted: false
    strictEqual ts.excludeQuoted, false
  test "works with '0' and '1' as well", ->
    ts = new VeriCiteSettings
      exclude_quoted: '1'
    strictEqual ts.excludeQuoted, true

  QUnit.module "VeriCiteSettings#toJSON"

  test "it converts back to snake_case", ->
    options =
      exclude_quoted: false
      exclude_self_plag: false
      originality_report_visibility: 'after_grading'
      store_in_index: false
    ts = new VeriCiteSettings options
    deepEqual ts.toJSON(), options

  QUnit.module "VeriCiteSettings#present",
    setup: ->
      @options =
        exclude_biblio: true
        originality_report_visibility: 'after_grading'
      @ts = new VeriCiteSettings @options
      @view = @ts.present()
