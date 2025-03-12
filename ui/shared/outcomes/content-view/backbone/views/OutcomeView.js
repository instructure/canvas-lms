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

import {useScope as createI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import $ from 'jquery'
import {map, maxBy, isEqual, isNaN, extend as lodashExtend} from 'lodash'
import OutcomeContentBase from './OutcomeContentBase'
import CalculationMethodFormView from './CalculationMethodFormView'
import outcomeTemplate from '../../jst/outcome.handlebars'
import outcomeFormTemplate from '../../jst/outcomeForm.handlebars'
import criterionTemplate from '../../jst/_criterion.handlebars'
import criterionHeaderTemplate from '../../jst/_criterionHeader.handlebars'
import {showConfirmOutcomeEdit} from '../../react/ConfirmOutcomeEditModal'
import {addCriterionInfoButton} from '../../react/CriterionInfo'
import 'jqueryui/dialog'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import {raw} from '@instructure/html-escape'
import {createRoot} from 'react-dom/client'
import {createElement} from 'react';
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('OutcomeView')

// For outcomes in the main content view.

export default class OutcomeView extends OutcomeContentBase {
  static initClass() {
    this.child('calculationMethodFormView', 'div.outcome-calculation-method-form')

    this.prototype.events = lodashExtend(
      {
        'click .edit_rating': 'editRating',
        'click .delete_rating_link': 'deleteRating',
        'click .save_rating_link': 'saveRating',
        'click .insert_rating': 'insertRating',
        'change .calculation_method': 'updateCalcMethod',
        'keyup .mastery_points': 'changeMasteryPoints',
      },
      OutcomeContentBase.prototype.events,
    )

    this.prototype.validations = lodashExtend(
      {
        display_name(data) {
          if (data.display_name.length > 255) {
            return I18n.t('length_error', 'Must be 255 characters or less')
          }
        },
        mastery_points(data) {
          if (
            !ENV.ACCOUNT_LEVEL_MASTERY_SCALES &&
            (isNaN(data.mastery_points) || data.mastery_points < 0)
          ) {
            return I18n.t('mastery_error', 'Must be greater than or equal to 0')
          }
        },
        calculation_int(data) {
          switch (data.calculation_method) {
            case 'decaying_average':
              if (isNaN(data.calculation_int) || data.calculation_int < 1 || data.calculation_int > 99) {
                return I18n.t('calculation_int_decaying_average_error', 'Must be between 1 and 99')
              }
              break
            case 'n_mastery':
              if (isNaN(data.calculation_int) || data.calculation_int < 1 || data.calculation_int > 10) {
                return I18n.t('calculation_int_n_mastery_error', 'Must be between 1 and 10')
              }
              break
          }
        }
      },
      OutcomeContentBase.prototype.validations,
    )
  }

  initialize({setQuizMastery, useForScoring, inFindDialog}) {
    this.setQuizMastery = setQuizMastery
    this.useForScoring = useForScoring
    this.inFindDialog = inFindDialog
    this.calculationMethodFormView = new CalculationMethodFormView({
      model: this.model,
    })
    this.originalConfirmableValues = this.getFormData()
    super.initialize(...arguments)
  }

  submit(event) {
    if (event != null) {
      event.preventDefault()
    }
    const newData = this.getFormData()
    return showConfirmOutcomeEdit({
      changed: !isEqual(newData, this.originalConfirmableValues),
      assessed: this.model.get('assessed'),
      hasUpdateableRubrics: this.model.get('has_updateable_rubrics'),
      modifiedFields: this.getModifiedFields(newData),
      onConfirm: _confirmEvent => super.submit(event),
    })
  }

  getModifiedFields(data) {
    if (ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
      return {}
    }
    return {
      masteryPoints:
        data.mastery_points !== numberHelper.parse(this.originalConfirmableValues.mastery_points),
      scoringMethod: !this.scoringMethodsEqual(data, this.originalConfirmableValues),
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
    if (ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
      delete data.mastery_points
      delete data.ratings
    } else {
      data.mastery_points = numberHelper.parse(data.mastery_points)
      data.ratings = map(data.ratings, rating =>
        lodashExtend(rating, {points: numberHelper.parse(rating.points)}),
      )
      if (['highest', 'latest'].includes(data.calculation_method)) {
        delete data.calculation_int
      } else {
        data.calculation_int = parseInt(numberHelper.parse(data.calculation_int), 10)
      }
    }
    return data
  }

  editRating(e) {
    e.preventDefault()
    const childIdx = $(e.currentTarget).closest('.rating').index()
    const $th = $(`.criterion thead tr > th:nth-child(${childIdx + 1})`)
    const $showWrapper = $(e.currentTarget).parents('.show:first')
    const $editWrapper = $showWrapper.next()

    $showWrapper.attr('aria-expanded', 'false').hide()
    $editWrapper.attr('aria-expanded', 'true').show()
    $th.find('h5').attr('aria-expanded', 'false').hide()
    return $editWrapper.find('.outcome_rating_description').focus()
  }

  // won't allow deleting the last rating
  deleteRating(e) {
    e.preventDefault()
    if (this.$('.rating').length > 1) {
      const deleteBtn = $(e.currentTarget)
      const childIdx = deleteBtn.closest('.rating').index()
      const $th = $(`.criterion thead tr > th:nth-child(${childIdx + 1})`)
      let focusTarget = deleteBtn.closest('.rating').prev().find('.insert_rating')
      if (focusTarget.length === 0) {
        focusTarget = deleteBtn.closest('.rating').next().find('.edit_rating')
      }
      $th.remove()
      deleteBtn.closest('td').remove()
      focusTarget.focus()
      return this.updateRatings()
    }
  }

  saveRating(e) {
    e.preventDefault()
    const childIdx = $(e.currentTarget).closest('.rating').index()
    const $th = $(`.criterion thead tr > th:nth-child(${childIdx + 1})`)
    const $editWrapper = $(e.currentTarget).parents('.edit:first')
    const $showWrapper = $editWrapper.prev()
    $th.find('h5').text($editWrapper.find('input.outcome_rating_description').val())
    let points = numberHelper.parse($editWrapper.find('input.outcome_rating_points').val())
    if (isNaN(points)) {
      points = 0
    } else {
      points = I18n.n(points, {precision: 2, strip_insignificant_zeros: true})
    }
    $showWrapper.find('.points').text(points)
    $editWrapper.attr('aria-expanded', 'false').hide()
    $showWrapper.attr('aria-expanded', 'true').show()
    $th.find('h5').attr('aria-expanded', 'true').show()
    $showWrapper.find('.edit_rating').focus()
    return this.updateRatings()
  }

  insertRating(e) {
    e.preventDefault()
    const $rating = $(criterionTemplate({description: '', points: '', _index: 99}))
    const childIdx = $(e.currentTarget).closest('.rating-header').index()
    const $ratingHeader = $(criterionHeaderTemplate({description: '', _index: 99}))
    const $tr = $('.criterion tbody tr')
    $(e.currentTarget).closest('.rating-header').after($ratingHeader)
    $tr.find(`> td:nth-child(${childIdx + 1})`).after($rating)
    $rating.find('.show').hide().next().show(200)
    $ratingHeader.hide().show(200)
    $rating.find('.edit input:first').focus()
    return this.updateRatings()
  }

  updateCalcMethod(e) {
    if (e != null) {
      e.preventDefault()
    }
    return this.model.set({
      calculation_method: $(e.target).val(),
    })
  }

  changeMasteryPoints(e) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    return (this.timeout = setTimeout(() => {
      const val = numberHelper.parse($(e.target).val())
      if (isNaN(val)) return
      if (val >= 0 && val <= this.model.get('points_possible')) {
        this.model.set({
          mastery_points: val,
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
      const rating = $(r).find('.outcome_rating_points').val() || 0
      total = maxBy([total, numberHelper.parse(rating)])
      for (const i of Array.from($(r).find('input'))) {
        // reset indices
        $(i).attr('name', i.name.replace(/\[[0-9]+\]/, `[${index}]`))
      }
    }
    const points = this.$('.points_possible')
    points.html(
      raw(
        I18n.t('%{points_possible} Points', {
          points_possible: I18n.n(total, {precision: 2, strip_insignificant_zeros: true}),
        }),
      ),
    )
    return this.model.set({
      points_possible: total,
    })
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
          outcomeFormTemplate(
            lodashExtend(data, {
              calculationMethods: this.model.calculationMethods(),
              hideMasteryScale: ENV.ACCOUNT_LEVEL_MASTERY_SCALES,
            }),
          ),
        )

        if (!ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
          addCriterionInfoButton(this.$el.find('#react-info-link')[0])
        }

        this._OutcomeFormInstUIInputs = this._createOutcomeFormInstUIInputs()
        this._renderAllOutcomeFormInstUIInputs()
        this.calculationMethodFormView.on(
          'instUIInputCreated',
          (payload) => this._OutcomeFormInstUIInputs.calculation_int = payload
        )
        this.readyForm()
        break
      case 'loading':
        this.$el.empty()
        break
      default: {
        // show
        if (!data.points_possible) {
          data.points_possible = 0
        }
        if (!data.mastery_points) {
          data.mastery_points = 0
        }

        if (ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
          if (ENV.MASTERY_SCALE?.outcome_proficiency) {
            data.ratings = ENV.MASTERY_SCALE.outcome_proficiency.ratings
            data.mastery_points = data.ratings.find(r => r.mastery).points
            data.points_possible = Math.max(...data.ratings.map(r => r.points))
          }
          if (ENV.MASTERY_SCALE?.outcome_calculation_method) {
            const methodModel = new CalculationMethodContent(
              ENV.MASTERY_SCALE.outcome_calculation_method,
            )
            lodashExtend(data, ENV.MASTERY_SCALE.outcome_calculation_method, methodModel.present())
          }
        }

        const can_manage = !this.readOnly() && this.model.canManage()
        const can_edit = can_manage && this.model.isNative()
        const can_unlink = can_manage && this.model.outcomeLink.can_unlink

        this.$el.html(
          outcomeTemplate(
            lodashExtend(data, {
              can_manage,
              can_edit,
              can_unlink,
              setQuizMastery: this.setQuizMastery,
              useForScoring: this.useForScoring,
              doNotRenderTitleLink: ENV.IS_LARGE_ROSTER || this.inFindDialog,
              hideMasteryScale:
                ENV.ACCOUNT_LEVEL_MASTERY_SCALES && !this.useForScoring && !this.setQuizMastery,
              assessedInContext:
                !this.readOnly() &&
                (this.model.outcomeLink.assessed ||
                  (this.model.isNative() && this.model.get('assessed'))),
            }),
          ),
        )
      }
    }

    this.$('input:first').focus()
    this.screenreaderTitleFocus()
    this._afterRender()

    this._outcomeMasteryAtContainer = (() => {
      const container = this.$('#outcome_mastery_at_container')[0]
      if(!container) return
      return createRoot(container)
    })()

    this._renderOutcomeMasteryAtInput()

    return this
  }

  showErrors(errors) {
    if (!this._OutcomeFormInstUIInputs) return
    this._renderAllOutcomeFormInstUIInputs()
    Object.keys(errors).forEach(key => {
      this._OutcomeFormInstUIInputs[key]?.render(errors[key])
    })
    for (const key in this._OutcomeFormInstUIInputs) {
      if (errors[key]) {
        this._OutcomeFormInstUIInputs[key]?.inputElement()?.focus()
        break
      }
    }
    // return super.showErrors(errors)
  }

  _renderOutcomeMasteryAtInput(errorType) {
    const errorMessage = {
      'NaNError': {type: 'newError', text: I18n.t('mastery_at_nan_error', 'Must be a number')},
      'rangeError': {type: 'newError', text: I18n.t('mastery_at_range_error', 'Must be between 1 and 99')},
    }[errorType]
    this._outcomeMasteryAtContainer?.render(createElement(View, { as:'div', margin: 'small' },
      createElement(TextInput, {
        name: 'mastery_at',
        id: 'outcome_mastery_at',
        renderLabel: ()=> createElement(Text, { weight: 'normal' }, 'Set mastery for any score at or above'),
        defaultValue: '60',
        width: '36ch',
        renderAfterInput: ()=> createElement('div', {}, '%'),
        messages: [
          {type: 'hint', text: I18n.t('mastery_at_hint', 'Must be between 1 and 99')},
          ...(errorMessage ? [errorMessage] : [])
        ]
      })
    ))
  }

  validateOutcomeMasteryAtInput(){
    const input = this.$('#outcome_mastery_at')[0]
    if (!input) return null
    const value = parseFloat(input.value)
    if (isNaN(value)) {
      this._renderOutcomeMasteryAtInput('NaNError')
      input.focus()
      return null
    }
    if(value < 1 || value > 99) {
      this._renderOutcomeMasteryAtInput('rangeError')
      input.focus()
      return null
    }
    return input.value
  }

  _createOutcomeFormInstUIInputs() {
    return {
      title: {
        root: (() => {
          const el = this.$('#title_container')[0]
          if(!el) return null
          return {rootElement: createRoot(el), initialValue: el.dataset.initialValue}
        })(),
        render: (errorMessages) => {
          this._OutcomeFormInstUIInputs.title.root?.rootElement.render(
            createElement(View, {as: 'div', margin: 'none none small none'},
              createElement(TextInput, {
                name: 'title',
                id: 'title',
                isRequired: true,
                defaultValue: this._OutcomeFormInstUIInputs.title.root?.initialValue,
                width: '40ch',
                placeholder: I18n.t('New Outcome'),
                renderLabel: ()=> createElement(ScreenReaderContent, null, I18n.t('title', 'Name this outcome')),
                messages: errorMessages?.map((m) => ({ text: m.message, type: 'newError' })),
              })
            )
          )
        },
        inputElement: () => this.$('#title')[0],
      },
      display_name: {
        root: (() => {
          const el = this.$('#display_name_container')[0]
          if(!el) return null
          return {rootElement: createRoot(el), initialValue: el.dataset.initialValue}
        })(),
        render: (errorMessages) => {
          this._OutcomeFormInstUIInputs.display_name.root?.rootElement.render(
            createElement(View, {as: 'div', margin: 'none none small none'},
              createElement(TextInput, {
                name: 'display_name',
                id: 'display_name',
                defaultValue: this._OutcomeFormInstUIInputs.display_name.root?.initialValue,
                width: '40ch',
                renderLabel: ()=> createElement(ScreenReaderContent, null, I18n.t('display_name', 'Friendly name')),
                messages: errorMessages?.map((m) => ({ text: m.message, type: 'newError' })),
              })
            )
          )
        },
        inputElement: () => this.$('#display_name')[0],
      },
      mastery_points: {
        root: (() => {
          const el = this.$('#mastery_point_container')[0]
          if(!el) return null
          return {rootElement: createRoot(el), initialValue: el.dataset.initialValue}
        })(),
        render: (errorMessages) => {
          this._OutcomeFormInstUIInputs.mastery_points.root?.rootElement.render(
            createElement(View, {as: 'div', margin: 'none none small none'},
              createElement(TextInput, {
                name: 'mastery_points',
                id: 'mastery_points',
                as: 'span',
                defaultValue: this._OutcomeFormInstUIInputs.mastery_points.root?.initialValue,
                display: 'inline-block',
                width: '8ch',
                renderLabel: ()=> createElement(ScreenReaderContent, null, I18n.t('mastery', 'mastery_at')),
                messages: errorMessages?.map((m) => ({ text: m.message, type: 'newError' })),
              })
            )
          )
        },
        inputElement: () => this.$('#mastery_points')[0],
      },
      // this stub will be replaced every time a 'instUIInputCreated' event is received.
      calculation_int: { render: ()=>{} },
    }
  }

  _renderAllOutcomeFormInstUIInputs() {
    for (const key in this._OutcomeFormInstUIInputs) {
      this._OutcomeFormInstUIInputs[key]?.render()
    }
  }
}
OutcomeView.initClass()
