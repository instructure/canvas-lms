#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'compiled/models/Outcome'
], (Outcome) ->

  QUnit.module "Outcome",

    setup: ->
      @accountOutcome =
        "context_type" : "Account"
        "context_id" : 1
        "outcome" :
          "title" : "Account Outcome"
          "context_type" : "Course"
          "context_id" : 1
          "calculation_method" : "decaying_average"
          "calculation_int" : 65
      @nativeOutcome =
        "context_type" : "Course"
        "context_id" : 2
        "outcome" :
          "title" : "Native Course Outcome"
          "context_type" : "Course"
          "context_id" : 2

  test "native returns true for a course outcome", ->
    outcome = new Outcome(@accountOutcome, { parse: true })
    equal outcome.isNative(), false

  test "native returns false for a course outcome imported from the account level", ->
    outcome = new Outcome(@nativeOutcome, { parse: true })
    equal outcome.isNative(), true

  test "default calculation method settings not set if calculation_method exists", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@accountOutcome, { parse: true })
    ok not spy.called

  test "default calculation method settings set if calculation_method is null", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@nativeOutcome, { parse: true })
    ok spy.calledOnce
