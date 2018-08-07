
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

import _ from 'underscore'
import I18n from 'i18n!outcomes'
import numberFormat from 'jsx/shared/helpers/numberFormat'

_.mixin({
  sum (array, accessor = null, start = 0) {
    return _.reduce(array, (memo, el) => (accessor != null ? accessor(el) : el) + memo, start)
  },
})

class DecayingAverage {
  constructor(weight, range) {
    this.weight = weight;
    this.range = range;
    this.rest = this.range.slice(0, +-2 + 1 || undefined);
    this.last = _.last(this.range);
  }

  value() {
    const n = ((_.sum(this.rest) / this.rest.length) * this.toPercentage(this.remainder())) +
      (this.last * this.toPercentage(this.weight));
    return Math.round(n * 100) / 100;
  }

  remainder() {
    return 100 - this.weight;
  }

  toPercentage(n) {
    return n / 100;
  }
}

class NMastery {
  constructor(n, mastery_points, range) {
    this.n = n;
    this.mastery_points = mastery_points;
    this.range = range;
  }

  aboveMastery() {
    return _.filter(this.range, n => (n >= this.mastery_points));
  }

  value() {
    if ((this.mastery_points != null) && (this.aboveMastery().length >= this.n)) {
      return Math.round((_.sum(this.aboveMastery()) / this.aboveMastery().length) * 100) / 100;
    } else {
      return I18n.t("N/A");
    }
  }
}

export default class CalculationMethodContent {
  constructor(model) {
    // We can pass in a straight object or a backbone model
    _.each([
      'calculation_method', 'calculation_int', 'mastery_points'
    ], attr => (this[attr] = (model.get != null) ? model.get(attr) : model[attr]));
  }

  decayingAverage() {
    return new DecayingAverage(this.calculation_int, this.exampleScoreIntegers()).value();
  }

  exampleScoreIntegers() {
    return [ 1, 4, 2, 3, 5, 3, 6 ];
  }

  nMastery() {
    return new NMastery(this.calculation_int, this.mastery_points, this.exampleScoreIntegers()).value();
  }

  present() {
    return this.toJSON()[this.calculation_method];
  }

  toJSON() {
    return {
      decaying_average: {
        method: I18n.t("%{recentInt}/%{remainderInt} Decaying Average", {
          recentInt: this.calculation_int,
          remainderInt: 100 - this.calculation_int
        }),
        friendlyCalculationMethod: I18n.t("Decaying Average"),
        calculationIntLabel: I18n.t("Last Item: "),
        calculationIntDescription: I18n.t('Between 1% and 99%'),
        exampleText: I18n.t(
          "Most recent result counts as %{calculation_int} of mastery weight, average of all other results count as %{remainder} of weight. If there is only one result, the single score will be returned.", {
            calculation_int: I18n.n(this.calculation_int, { percentage: true }),
            remainder: I18n.n(100 - this.calculation_int, { percentage: true })
          }
        ),
        exampleScores: this.exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(this.decayingAverage())
      },
      n_mastery: {
        method: I18n.t({
          one: "Achieve mastery one time",
          other: "Achieve mastery %{count} times"
        }, {
          count: this.calculation_int
        }),
        friendlyCalculationMethod: I18n.t("n Number of Times"),
        calculationIntLabel: I18n.t('Items: '),
        calculationIntDescription: I18n.t('Between 1 and 5'),
        exampleText: I18n.t(
          {
            one: "Must achieve mastery at least one time. Scores above mastery will be averaged to calculate final score.",
            other: "Must achieve mastery at least %{count} times. Scores above mastery will be averaged to calculate final score."
          }, {
              count: this.calculation_int
          }),
        exampleScores: this.exampleScoreIntegers().join(', '),
        exampleResult: numberFormat.outcomeScore(this.nMastery())
      },
      latest: {
        method: I18n.t("Latest Score"),
        friendlyCalculationMethod: I18n.t("Most Recent Score"),
        exampleText: I18n.t("Mastery score reflects the most recent graded assignment or quiz."),
        exampleScores: this.exampleScoreIntegers().slice(0, 4).join(', '),
        exampleResult: numberFormat.outcomeScore(_.last(this.exampleScoreIntegers().slice(0, 4)))
      },
      highest: {
        method: I18n.t("Highest Score"),
        friendlyCalculationMethod: I18n.t("Highest Score"),
        exampleText: I18n.t("Mastery score reflects the highest score of a graded assignment or quiz."),
        exampleScores: this.exampleScoreIntegers().slice(0, 4).join(', '),
        exampleResult: numberFormat.outcomeScore(_.max(this.exampleScoreIntegers().slice(0, 4)))
      }
    };
  }
}

