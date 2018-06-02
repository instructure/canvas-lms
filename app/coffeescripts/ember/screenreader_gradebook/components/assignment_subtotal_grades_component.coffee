#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'i18nObj'
  'ember'
  '../../../util/round'
  'jsx/gradebook/GradingSchemeHelper'
], (I18n, Ember, round, {scoreToGrade}) ->

  AssignmentSubtotalGradesComponent = Ember.Component.extend

    tagName: ''
    subtotal: null
    student: null
    weightingScheme: null
    gradingStandard: null
    hasGrade: Ember.computed.bool('values.possible')
    hasWeightedGroups: Ember.computed.equal('weightingScheme', 'percent')

    letterGrade:(->
      standard = @get('gradingStandard')
      return null unless standard and @get('hasGrade')
      percentage = parseFloat(@get('rawPercent').toPrecision(4))
      scoreToGrade(percentage, standard)
    ).property('gradingStandard', 'hasGrade')

    values:(->
      student = @get('student')
      Ember.get(student, "#{@get('subtotal.key')}")
    ).property('subtotal', 'student', 'student.total_grade')

    points: (->
      values = @get('values')
      "#{I18n.n(round(values.score, round.DEFAULT))} / #{I18n.n(round(values.possible, round.DEFAULT))}"
    ).property('values')

    # This method returns the raw percentage, float errors and all e.g. 54.5 / 100 * 100 will return 54.50000000000001
    # It's use is in any further calculations so we're not using a pre-rounded number.
    rawPercent:(->
      values = @get('values')
      values.score / values.possible * 100
    ).property('values')

    percent:(->
      I18n.n(round(@get('rawPercent'), round.DEFAULT), percentage: true)
    ).property('values')

    scoreDetail:(->
      points = @get('points')
      "(#{points})"
    ).property('points')

    weight:(->
      I18n.n(@get('subtotal').weight, percentage: true)
    ).property('subtotal')
