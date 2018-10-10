//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import I18n from 'i18n!outcomes'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import $ from 'jquery'
import _ from 'underscore'
import OutcomeContentBase from './OutcomeContentBase'
import CalculationMethodFormView from './CalculationMethodFormView'
import outcomeTemplate from 'jst/outcomes/outcome'
import outcomeFormTemplate from 'jst/outcomes/outcomeForm'
import criterionTemplate from 'jst/outcomes/_criterion'
import confirmOutcomeEditModal, {showConfirmOutcomeEdit} from 'jsx/outcomes/ConfirmOutcomeEditModal'
import 'jqueryui/dialog'

// For outcomes in the main content view.

export default class OutcomeView extends OutcomeContentBase {
  static initClass() {
    this.child('calculationMethodFormView', 'div.outcome-calculation-method-form')

    this.prototype.events = _.extend(
      {
        'click .outcome_information_link': 'showRatingDialog',
        'click .edit_rating': 'editRating',
        'click .delete_rating_link': 'deleteRating',
        'click .save_rating_link': 'saveRating',
        'click .insert_rating': 'insertRating',
        'change .calculation_method': 'updateCalcMethod',
        'keyup .mastery_points': 'changeMasteryPoints'
      },
      OutcomeContentBase.prototype.events
    )

    this.prototype.validations = _.extend(
      {
        display_name(data) {
          if (data.display_name.length > 255) {
            return I18n.t('length_error', 'Must be 255 characters or less')
          }
        },
        mastery_points(data) {
          if (_.isNaN(data.mastery_points) || data.mastery_points < 0) {
            return I18n.t('mastery_error', 'Must be greater than or equal to 0')
          }
        }
      },
      OutcomeContentBase.prototype.validations
    )
  }

  constructor({setQuizMastery, useForScoring}) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.editRating = this.editRating.bind(this)
    this.deleteRating = this.deleteRating.bind(this)
    this.insertRating = this.insertRating.bind(this)
    this.updateCalcMethod = this.updateCalcMethod.bind(this)
    this.showRatingDialog = this.showRatingDialog.bind(this)
    this.setQuizMastery = setQuizMastery
    this.useForScoring = useForScoring
    super(...arguments)
    this.calculationMethodFormView = new CalculationMethodFormView({
      model: this.model
    })
    this.originalConfirmableValues = this.getFormData()
  }

  submit(event) {
    if (event != null) {
      event.preventDefault()
    }
    const newData = this.getFormData()
    return showConfirmOutcomeEdit({
      changed: !_.isEqual(newData, this.originalConfirmableValues),
      assessed: this.model.get('assessed'),
      hasUpdateableRubrics: this.model.get('has_updateable_rubrics'),
      modifiedFields: this.getModifiedFields(newData),
      onConfirm: _confirmEvent => OutcomeView.prototype.__proto__.submit.call(this, event) // super == submit
    })
  }

  getModifiedFields(data) {
    return {
      masteryPoints:
        data.mastery_points !== numberHelper.parse(this.originalConfirmableValues.mastery_points),
      scoringMethod: !this.scoringMethodsEqual(data, this.originalConfirmableValues)
    }
  }

  scoringMethodsEqual(lhs, rhs) {
    if (lhs.calculation_method !== rhs.calculation_method) return false
    if (['highest', 'latest'].includes(lhs.calculation_method)) return true
    return numberHelper.parse(lhs.calculation_int) === numberHelper.parse(rhs.calculation_int)
  }

  edit(event) {
    super.edit(event)
    this.originalConfirmableValues = this.getFormData()

    // account for text editor possibly updating description
    return setTimeout(() => (this.originalConfirmableValues = this.getFormData()), 50)
  }

  // overriding superclass
  getFormData() {
    const data = super.getFormData()
    data.mastery_points = numberHelper.parse(data.mastery_points)
    data.ratings = _.map(data.ratings, rating =>
      _.extend(rating, {points: numberHelper.parse(rating.points)})
    )
    if (['highest', 'latest'].includes(data.calculation_method)) {
      delete data.calculation_int
    } else {
      data.calculation_int = parseInt(numberHelper.parse(data.calculation_int))
    }
    return data
  }

  editRating(e) {
    e.preventDefault()
    const $showWrapper = $(e.currentTarget).parents('.show:first')
    const $editWrapper = $showWrapper.next()

    $showWrapper.attr('aria-expanded', 'false').hide()
    $editWrapper.attr('aria-expanded', 'true').show()
    return $editWrapper.find('.outcome_rating_description').focus()
  }

  // won't allow deleting the last rating
  deleteRating(e) {
    e.preventDefault()
    if (this.$('.rating').length > 1) {
      const deleteBtn = $(e.currentTarget)
      let focusTarget = deleteBtn
        .closest('.rating')
        .prev()
        .find('.insert_rating')
      if (focusTarget.length === 0) {
        focusTarget = deleteBtn
          .closest('.rating')
          .next()
          .find('.edit_rating')
      }
      deleteBtn.closest('td').remove()
      focusTarget.focus()
      return this.updateRatings()
    }
  }

  saveRating(e) {
    e.preventDefault()
    const $editWrapper = $(e.currentTarget).parents('.edit:first')
    const $showWrapper = $editWrapper.prev()
    $showWrapper.find('h5').text($editWrapper.find('input.outcome_rating_description').val())
    let points = numberHelper.parse($editWrapper.find('input.outcome_rating_points').val())
    if (_.isNaN(points)) {
      points = 0
    } else {
      points = I18n.n(points, {precision: 2, strip_insignificant_zeros: true})
    }
    $showWrapper.find('.points').text(points)
    $editWrapper.attr('aria-expanded', 'false').hide()
    $showWrapper.attr('aria-expanded', 'true').show()
    $showWrapper.find('.edit_rating').focus()
    return this.updateRatings()
  }

  insertRating(e) {
    e.preventDefault()
    const $rating = $(criterionTemplate({description: '', points: '', _index: 99}))
    $(e.currentTarget)
      .closest('.rating')
      .after($rating)
    $rating
      .find('.show')
      .hide()
      .next()
      .show(200)
    $rating.find('.edit input:first').focus()
    return this.updateRatings()
  }

  updateCalcMethod(e) {
    if (e != null) {
      e.preventDefault()
    }
    return this.model.set({
      calculation_method: $(e.target).val()
    })
  }

  changeMasteryPoints(e) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    return (this.timeout = setTimeout(() => {
      const val = numberHelper.parse($(e.target).val())
      if (_.isNaN(val)) return
      if (val >= 0 && val <= this.model.get('points_possible')) {
        this.model.set({
          mastery_points: val
        })
        if (this.calculationMethodFormView) this.calculationMethodFormView.render()
      }
    }, 500))
  }

  // Update rating form field elements and the total.
  updateRatings() {
    let total = 0
    const iterable = this.$('.rating')
    for (let index = 0; index < iterable.length; index++) {
      const r = iterable[index]
      const rating =
        $(r)
          .find('.outcome_rating_points')
          .val() || 0
      total = _.max([total, numberHelper.parse(rating)])
      for (const i of Array.from($(r).find('input'))) {
        // reset indices
        $(i).attr('name', i.name.replace(/\[[0-9]+\]/, `[${index}]`))
      }
    }
    const points = this.$('.points_possible')
    points.html(
      $.raw(
        I18n.t('%{points_possible} Points', {
          points_possible: I18n.n(total, {precision: 2, strip_insignificant_zeros: true})
        })
      )
    )
    return this.model.set({
      points_possible: total
    })
  }

  showRatingDialog(e) {
    e.preventDefault()
    $('#outcome_criterion_dialog')
      .dialog({
        autoOpen: false,
        title: I18n.t('outcome_criterion', 'Learning Outcome Criterion'),
        width: 400,
        close() {
          $(e.target).focus()
        }
      })
      .dialog('open')
  }

  screenreaderTitleFocus() {
    return this.$('.screenreader-outcome-title').focus()
  }

  render() {
    const data = this.model.present()
    data.html_url = `${ENV.CONTEXT_URL_ROOT}/outcomes/${data.id}`
    this.calculationMethodFormView.state = this.state
    switch (this.state) {
      case 'edit':
      case 'add':
        this.$el.html(
          outcomeFormTemplate(_.extend(data, {calculationMethods: this.model.calculationMethods()}))
        )
        this.readyForm()
        break
      case 'loading':
        this.$el.empty()
        break
      default:
        // show
        if (!data.points_possible) {
          data.points_possible = 0
        }
        if (!data.mastery_points) {
          data.mastery_points = 0
        }
        var can_manage = !this.readOnly() && this.model.canManage()
        var can_edit = can_manage && this.model.isNative()
        var can_unlink = can_manage && this.model.outcomeLink.can_unlink

        this.$el.html(
          outcomeTemplate(
            _.extend(data, {
              can_manage,
              can_edit,
              can_unlink,
              setQuizMastery: this.setQuizMastery,
              useForScoring: this.useForScoring,
              isLargeRoster: ENV.IS_LARGE_ROSTER,
              assessedInContext:
                !this.readOnly() &&
                (this.model.outcomeLink.assessed ||
                  (this.model.isNative() && this.model.get('assessed')))
            })
          )
        )
    }

    this.$('input:first').focus()
    this.screenreaderTitleFocus()
    this._afterRender()
    return this
  }
}
OutcomeView.initClass()
