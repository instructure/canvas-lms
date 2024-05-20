// Copyright (C) 2015 - present Instructure, Inc.

// This file is part of Canvas.

// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.

// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.

// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {mixin, reduce, each, max, last, filter, sum} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberFormat from '@canvas/i18n/numberFormat'

const I18n = useI18nScope('CalculationMethodContent')

mixin({
  sum(array, accessor = null, start = 0) {
    return reduce(array, (memo, el) => (accessor != null ? accessor(el) : el) + memo, start)
  },
})

const eachCons = (array, num) => {
  return Array.from({length: array.length - num + 1}, (_, i) => array.slice(i, i + num))
}

class WeightedAverage {
  constructor(weight, range) {
    this.weight = weight
    this.range = range
    this.rest = this.range.slice(0, +-2 + 1 || undefined)
    this.last = last(this.range)
  }

  value() {
    const n =
      (sum(this.rest) / this.rest.length) * this.toPercentage(this.remainder()) +
      this.last * this.toPercentage(this.weight)
    return Math.round(n * 100) / 100
  }

  remainder() {
    return 100 - this.weight
  }

  toPercentage(n) {
    return n / 100
  }
}

class DecayingAverage {
  constructor(weight, range) {
    this.weight = weight
    this.range = range
  }

  value() {
    let n = null
    const consArray = eachCons(this.range, 2)
    consArray.forEach(score => {
      n =
        n == null
          ? this.calculateDecayAverage(score[0], score[1])
          : this.calculateDecayAverage(n, score[1])
    })

    return Math.round(n * 100) / 100
  }

  remainder() {
    return 100 - this.weight
  }

  toPercentage(n) {
    return n / 100
  }

  calculateDecayAverage(score1, score2) {
    return score1 * this.toPercentage(this.remainder()) + score2 * this.toPercentage(this.weight)
  }
}

class NMastery {
  constructor(n, mastery_points, range) {
    this.n = n
    this.mastery_points = mastery_points
    this.range = range
  }

  aboveMastery() {
    return filter(this.range, n => n >= this.mastery_points)
  }

  value() {
    if (this.mastery_points != null && this.aboveMastery().length >= this.n) {
      return Math.round((sum(this.aboveMastery()) / this.aboveMastery().length) * 100) / 100
    } else {
      return I18n.t('N/A')
    }
  }
}

class Average {
  constructor(range) {
    this.range = range
  }

  value() {
    if (this.range.length > 0) {
      return Math.round((sum(this.range) / this.range.length) * 100) / 100
    } else {
      return I18n.t('N/A')
    }
  }
}

export default class CalculationMethodContent {
  constructor(model) {
    // We can pass in a straight object or a backbone model
    each(
      ['calculation_method', 'calculation_int', 'mastery_points', 'is_individual_outcome'],
      attr => (this[attr] = model.get != null ? model.get(attr) : model[attr])
    )
  }

  weightedAverage() {
    return new WeightedAverage(this.calculation_int, this.exampleScoreIntegers()).value()
  }

  decayingAverage() {
    return new DecayingAverage(
      this.calculation_int,
      this.exampleScoreIntegers().slice(0, 7)
    ).value()
  }

  exampleScoreIntegers() {
    return [1, 4, 2, 3, 5, 3, 6, 1, 4, 2, 3, 5, 3, 6]
  }

  nMastery() {
    return new NMastery(
      this.calculation_int,
      this.mastery_points,
      this.exampleScoreIntegers()
    ).value()
  }

  average(range) {
    return new Average(range).value()
  }

  present() {
    const newDecayingAverageFF = ENV.OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION
    let calculation_method_name = this.calculation_method
    if (newDecayingAverageFF) {
      calculation_method_name =
        this.calculation_method === 'decaying_average'
          ? 'weighted_average'
          : this.calculation_method
    } else {
      calculation_method_name =
        this.calculation_method === 'standard_decaying_average'
          ? 'decaying_average'
          : this.calculation_method
    }
    return this.toJSON()[calculation_method_name]
  }

  calculationValuesForIndividualOutcomes(newDecayingAverageFF) {
    let decayWeightAvgValues = {}
    const otherCalculationValues = {
      n_mastery: {
        calculationIntLabel: I18n.t('# of times'),
        calculationIntDescription: I18n.t('must be between 1 and 10'),
      },
      latest: {
        method: I18n.t('Most Recent Score'),
      },
      highest: {
        exampleScores: this.exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(max(this.exampleScoreIntegers())),
      },
      average: {
        method: I18n.t('Average'),
      },
    }

    if (newDecayingAverageFF) {
      decayWeightAvgValues = {
        weighted_average: {
          method: I18n.t('Weighted Average - %{recentInt}%/%{remainderInt}%', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('% weighting for last item'),
          calculationIntDescription: I18n.t('must be between 1 and 99'),
        },
        decaying_average: {
          method: I18n.t('Decaying Average - %{recentInt}%/%{remainderInt}%', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('% weighting of most recent item'),
          calculationIntDescription: I18n.t('must be between 50 and 99'),
        },
      }
    } else {
      decayWeightAvgValues = {
        decaying_average: {
          method: I18n.t('Decaying Average - %{recentInt}%/%{remainderInt}%', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('% weighting for last item'),
          calculationIntDescription: I18n.t('must be between 1 and 99'),
        },
      }
    }
    return Object.assign(decayWeightAvgValues, otherCalculationValues)
  }

  calculationValuesForNonIndividualOutcomes(newDecayingAverageFF) {
    let decayWeightAvgValues = {}
    const otherCalculationValues = {
      n_mastery: {
        calculationIntLabel: I18n.t('Items: '),
        calculationIntDescription: I18n.t('Between 1 and 10'),
      },
      latest: {
        method: I18n.t('Latest Score'),
      },
      highest: {
        exampleScores: this.exampleScoreIntegers().slice(0, 4).join(', '),
        exampleResult: numberFormat.outcomeScore(max(this.exampleScoreIntegers().slice(0, 4))),
      },
      average: {
        method: I18n.t('Average'),
      },
    }

    if (newDecayingAverageFF) {
      decayWeightAvgValues = {
        weighted_average: {
          method: I18n.t('%{recentInt}/%{remainderInt} Weighted Average', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('Last Item: '),
          calculationIntDescription: I18n.t('Between 1% and 99%'),
        },
        decaying_average: {
          method: I18n.t('%{recentInt}/%{remainderInt} Decaying Average', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('Most Recent Item: '),
          calculationIntDescription: I18n.t('Between 50% and 99%'),
        },
      }
    } else {
      decayWeightAvgValues = {
        decaying_average: {
          method: I18n.t('%{recentInt}/%{remainderInt} Decaying Average', {
            recentInt: this.calculation_int,
            remainderInt: 100 - this.calculation_int,
          }),
          calculationIntLabel: I18n.t('Last Item: '),
          calculationIntDescription: I18n.t('Between 1% and 99%'),
        },
      }
    }
    return Object.assign(decayWeightAvgValues, otherCalculationValues)
  }

  toJSON() {
    const newDecayingAverageFF = ENV.OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION
    const alternativeCalculationValues = this.is_individual_outcome
      ? this.calculationValuesForIndividualOutcomes(newDecayingAverageFF)
      : this.calculationValuesForNonIndividualOutcomes(newDecayingAverageFF)

    let finalCalculationMethods = {}
    const legacyDecayingAvgFormat = {
      method: alternativeCalculationValues.decaying_average.method,
      friendlyCalculationMethod: I18n.t('Decaying Average'),
      calculationIntLabel: alternativeCalculationValues.decaying_average.calculationIntLabel,
      calculationIntDescription:
        alternativeCalculationValues.decaying_average.calculationIntDescription,
      exampleText: I18n.t(
        'Most recent result counts as %{calculation_int} of mastery weight, average of all other results count as %{remainder} of weight. If there is only one result, the single score will be returned.',
        {
          calculation_int: I18n.n(this.calculation_int, {percentage: true}),
          remainder: I18n.n(100 - this.calculation_int, {percentage: true}),
        }
      ),
      exampleScores: this.exampleScoreIntegers().join(', '),
      exampleResult: numberFormat.outcomeScore(this.weightedAverage()),
      defaultInt: 65,
      validRange: [1, 99],
    }

    if (newDecayingAverageFF) {
      finalCalculationMethods = {
        weighted_average: {
          method: alternativeCalculationValues.weighted_average.method,
          friendlyCalculationMethod: I18n.t('Weighted Average'),
          calculationIntLabel: alternativeCalculationValues.weighted_average.calculationIntLabel,
          calculationIntDescription:
            alternativeCalculationValues.weighted_average.calculationIntDescription,
          exampleText: I18n.t(
            'Most recent result counts as %{calculation_int} of mastery weight, average of all other results count as %{remainder} of weight. If there is only one result, the single score will be returned.',
            {
              calculation_int: I18n.n(this.calculation_int, {percentage: true}),
              remainder: I18n.n(100 - this.calculation_int, {percentage: true}),
            }
          ),
          exampleScores: this.exampleScoreIntegers().join(', '),
          exampleResult: numberFormat.outcomeScore(this.weightedAverage()),
          defaultInt: 65,
          validRange: [1, 99],
        },
        standard_decaying_average: {
          method: alternativeCalculationValues.decaying_average.method,
          friendlyCalculationMethod: I18n.t('Decaying Average'),
          calculationIntLabel: alternativeCalculationValues.decaying_average.calculationIntLabel,
          calculationIntDescription:
            alternativeCalculationValues.decaying_average.calculationIntDescription,
          exampleText: I18n.t(
            'Between two assessments, the most recent assessment gets %{calculation_int} weight, and the first gets %{remainder}. For each additional assessment, the sum of the previous score calculations decay by an additional %{remainder}. If there is only one result, the single score will be returned.',
            {
              calculation_int: I18n.n(this.calculation_int, {percentage: true}),
              remainder: I18n.n(100 - this.calculation_int, {percentage: true}),
            }
          ),
          exampleScores: this.exampleScoreIntegers().slice(0, 7).join(', '),
          exampleResult: numberFormat.outcomeScore(this.decayingAverage()),
          defaultInt: 65,
          validRange: [50, 99],
        },
      }
    } else {
      finalCalculationMethods = {
        decaying_average: legacyDecayingAvgFormat,
      }
    }

    return Object.assign(finalCalculationMethods, {
      n_mastery: {
        method: I18n.t(
          {
            one: 'Achieve mastery one time',
            other: 'Achieve mastery %{count} times',
          },
          {
            count: this.calculation_int,
          }
        ),
        friendlyCalculationMethod: I18n.t('n Number of Times'),
        calculationIntLabel: alternativeCalculationValues.n_mastery.calculationIntLabel,
        calculationIntDescription: alternativeCalculationValues.n_mastery.calculationIntDescription,
        exampleText: I18n.t(
          {
            one: 'Must achieve mastery at least one time. Scores above mastery will be averaged to calculate final score.',
            other:
              'Must achieve mastery at least %{count} times. Scores above mastery will be averaged to calculate final score.',
          },
          {
            count: this.calculation_int,
          }
        ),
        exampleScores: this.exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(this.nMastery()),
        defaultInt: 5,
        validRange: [1, 10],
      },
      latest: {
        method: alternativeCalculationValues.latest.method,
        friendlyCalculationMethod: I18n.t('Most Recent Score'),
        exampleText: I18n.t('Mastery score reflects the most recent graded assignment or quiz.'),
        exampleScores: this.exampleScoreIntegers().slice(0, 4).join(', '),
        exampleResult: numberFormat.outcomeScore(last(this.exampleScoreIntegers().slice(0, 4))),
      },
      highest: {
        method: I18n.t('Highest Score'),
        friendlyCalculationMethod: I18n.t('Highest Score'),
        exampleText: I18n.t(
          'Mastery score reflects the highest score of a graded assignment or quiz.'
        ),
        exampleScores: alternativeCalculationValues.highest.exampleScores,
        exampleResult: alternativeCalculationValues.highest.exampleResult,
      },
      average: {
        method: alternativeCalculationValues.average.method,
        friendlyCalculationMethod: I18n.t('Average'),
        exampleText: I18n.t(
          'Central value in a set of results. Calculated by dividing the sum of all item scores by the number of scores.'
        ),
        exampleWarning: I18n.t(
          'Average is not a good fit for most outcomes-based or mastery-based learning use cases because students may need time to reach mastery of an outcome and early poorer performance can bring down an average.'
        ),
        exampleScores: this.exampleScoreIntegers().slice(0, 7).join(', '),
        exampleResult: numberFormat.outcomeScore(
          this.average(this.exampleScoreIntegers().slice(0, 7))
        ),
      },
    })
  }
}
