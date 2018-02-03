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
  'underscore'
  'i18n!outcomes'
  'jsx/shared/helpers/numberFormat'
  '../../underscore-ext/sum'
], (_, I18n, numberFormat) ->
  class DecayingAverage
    constructor: (@weight, @range) ->
      @rest = @range[..-2]
      @last = _.last(@range)

    value: ->
      n = ((_.sum(@rest) / @rest.length) * @toPercentage(@remainder())) +
        (@last * @toPercentage(@weight))
      Math.round(n * 100) / 100

    remainder: ->
      100 - @weight

    toPercentage: (n) ->
      n / 100

  class NMastery
    constructor: (@n, @mastery_points, @range) ->

    aboveMastery: ->
      _.filter(@range, (n) =>
        n >= @mastery_points
      )

    value: ->
      if @mastery_points? && @aboveMastery().length >= @n
        Math.round(_.sum(@aboveMastery()) / @aboveMastery().length * 100) / 100
      else
        I18n.t("N/A")

  class CalculationMethodContent
    constructor: (model) ->
      # We can pass in a straight object or a backbone model
      _.each([
        'calculation_method', 'calculation_int', 'mastery_points'
      ], (attr) =>
        @[attr] = if model.get? then model.get(attr) else model[attr]
      )

    decayingAverage: ->
      new DecayingAverage(@calculation_int, @exampleScoreIntegers()).value()

    exampleScoreIntegers: ->
      [ 1, 4, 2, 3, 5, 3, 6 ]

    nMastery: ->
      new NMastery(@calculation_int, @mastery_points, @exampleScoreIntegers()).value()

    present: ->
      @toJSON()[@calculation_method]

    toJSON: ->
      decaying_average:
        method: I18n.t("%{recentInt}/%{remainderInt} Decaying Average", {
          recentInt: @calculation_int
          remainderInt: 100 - @calculation_int
        })
        friendlyCalculationMethod: I18n.t("Decaying Average")
        calculationIntLabel: I18n.t("Last Item: ")
        calculationIntDescription: I18n.t('Between 1% and 99%')
        exampleText: I18n.t(
          "Most recent result counts as %{calculation_int} of mastery weight, average of all other results count as %{remainder} of weight. If there is only one result, the single score will be returned.", {
            calculation_int: I18n.n(@calculation_int, { percentage: true }),
            remainder: I18n.n(100 - @calculation_int, { percentage: true })
          }
        ),
        exampleScores: @exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(@decayingAverage())
      n_mastery:
        method: I18n.t({
          one: "Achieve mastery one time",
          other: "Achieve mastery %{count} times"
        }, {
          count: @calculation_int
        })
        friendlyCalculationMethod: I18n.t("n Number of Times")
        calculationIntLabel: I18n.t('Items: ')
        calculationIntDescription: I18n.t('Between 1 and 5')
        exampleText: I18n.t(
          {
            one: "Must achieve mastery at least one time. Scores above mastery will be averaged to calculate final score.",
            other: "Must achieve mastery at least %{count} times. Scores above mastery will be averaged to calculate final score."
          }, {
              count: @calculation_int
          }),
        exampleScores: @exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(@nMastery())
      latest:
        method: I18n.t("Latest Score")
        friendlyCalculationMethod: I18n.t("Most Recent Score")
        exampleText: I18n.t("Mastery score reflects the most recent graded assignment or quiz."),
        exampleScores: @exampleScoreIntegers()[..3].join(', '),
        exampleResult: numberFormat.outcomeScore(_.last(@exampleScoreIntegers()[..3]))
      highest:
        method: I18n.t("Highest Score")
        friendlyCalculationMethod: I18n.t("Highest Score")
        exampleText: I18n.t("Mastery score reflects the highest score of a graded assignment or quiz."),
        exampleScores: @exampleScoreIntegers()[..3].join(', '),
        exampleResult: numberFormat.outcomeScore(_.max(@exampleScoreIntegers()[..3]))
