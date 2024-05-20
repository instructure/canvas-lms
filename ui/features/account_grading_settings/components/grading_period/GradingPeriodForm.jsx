/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import update from 'immutability-helper'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'
import numberHelper from '@canvas/i18n/numberHelper'
import round from '@canvas/round'
import {isEqual} from 'lodash'

const I18n = useI18nScope('gradingPeriodForm')

function roundWeight(val) {
  const value = numberHelper.parse(val)
  return Number.isNaN(value) ? null : round(value, 2)
}

function buildPeriod(attr) {
  return {
    id: attr.id,
    title: attr.title,
    weight: roundWeight(attr.weight),
    startDate: attr.startDate,
    endDate: attr.endDate,
    closeDate: attr.closeDate,
  }
}

class GradingPeriodForm extends React.Component {
  static propTypes = {
    period: PropTypes.shape({
      id: PropTypes.string,
      title: PropTypes.string.isRequired,
      weight: PropTypes.number,
      startDate: PropTypes.instanceOf(Date).isRequired,
      endDate: PropTypes.instanceOf(Date).isRequired,
      closeDate: PropTypes.instanceOf(Date),
    }),
    weighted: PropTypes.bool.isRequired,
    disabled: PropTypes.bool.isRequired,
    onSave: PropTypes.func.isRequired,
    onCancel: PropTypes.func.isRequired,
  }

  constructor(props, context) {
    super(props, context)
    const period = buildPeriod(props.period || {})
    this.titleRef = null

    this.state = {
      period,
      preserveCloseDate: this.hasDistinctCloseDate(period),
    }
  }

  componentDidMount() {
    this.hackTheDatepickers()
    this.titleRef?.focus()
  }

  triggerSave = () => {
    if (this.props.onSave) {
      this.props.onSave(this.state.period)
    }
  }

  triggerCancel = () => {
    if (this.props.onCancel) {
      this.setState({period: buildPeriod({})}, this.props.onCancel)
    }
  }

  hasDistinctCloseDate = ({endDate, closeDate}) => closeDate && !isEqual(endDate, closeDate)

  mergePeriod = attr => update(this.state.period, {$merge: attr})

  changeTitle = e => {
    const period = this.mergePeriod({title: e.target.value})
    this.setState({period})
  }

  changeWeight = e => {
    const period = this.mergePeriod({weight: roundWeight(e.target.value)})
    this.setState({period})
  }

  changeStartDate = date => {
    const period = this.mergePeriod({startDate: date})
    this.setState({period})
  }

  changeEndDate = date => {
    const attr = {endDate: date}
    if (!this.state.preserveCloseDate && !this.hasDistinctCloseDate(this.state.period)) {
      attr.closeDate = date
    }
    const period = this.mergePeriod(attr)
    this.setState({period})
  }

  changeCloseDate = date => {
    const period = this.mergePeriod({closeDate: date})
    this.setState({period, preserveCloseDate: !!date})
  }

  hackTheDatepickers = () => {
    // This can be replaced when we have an extensible datepicker
    const $form = ReactDOM.findDOMNode(this)
    const $appends = $form.querySelectorAll('.input-append')
    $appends.forEach($el => {
      $el.classList.add('ic-Input-group')
    })

    const $dateFields = $form.querySelectorAll('.date_field')
    $dateFields.forEach($el => {
      $el.classList.remove('date_field')
      $el.classList.add('ic-Input')
    })

    const $buttons = $form.querySelectorAll('.ui-datepicker-trigger')
    $buttons.forEach($el => {
      $el.classList.remove('btn')
      $el.classList.add('Button')
    })
  }

  renderSaveAndCancelButtons = () => (
    <div className="ic-Form-actions below-line">
      <Button disabled={this.props.disabled} onClick={this.triggerCancel}>
        {I18n.t('Cancel')}
      </Button>
      &nbsp;
      <Button
        color="primary"
        aria-label={I18n.t('Save Grading Period')}
        disabled={this.props.disabled}
        onClick={this.triggerSave}
      >
        {I18n.t('Save')}
      </Button>
    </div>
  )

  renderWeightInput = () => {
    if (!this.props.weighted) return null
    return (
      <div className="ic-Form-control">
        <label className="ic-Label" htmlFor="weight">
          {I18n.t('Grading Period Weight')}
        </label>
        <div className="input-append">
          <input
            id="weight"
            type="text"
            className="span1"
            defaultValue={I18n.n(this.state.period.weight)}
            onChange={this.changeWeight}
          />
          <span className="add-on">%</span>
        </div>
      </div>
    )
  }

  render() {
    const accountLabel = I18n.t('#helpers.account_time', 'Account')
    return (
      <div className="GradingPeriodForm">
        <div className="grid-row">
          <div className="col-xs-12 col-lg-8">
            <div className="ic-Form-group ic-Form-group--horizontal">
              <div className="ic-Form-control">
                <label className="ic-Label" htmlFor="title">
                  {I18n.t('Grading Period Title')}
                </label>
                <input
                  id="title"
                  ref={ref => {
                    this.titleRef = ref
                  }}
                  className="ic-Input"
                  title={I18n.t('Grading Period Title')}
                  defaultValue={this.state.period.title}
                  onChange={this.changeTitle}
                  type="text"
                />
              </div>

              <div className="ic-Form-control">
                <label id="start-date-label" htmlFor="start-date" className="ic-Label">
                  {I18n.t('Start Date')}
                </label>
                <DueDateCalendarPicker
                  disabled={false}
                  inputClasses=""
                  dateValue={this.state.period.startDate}
                  dateType="due_at"
                  handleUpdate={this.changeStartDate}
                  rowKey="start-date"
                  labelledBy="start-date-label"
                  isFancyMidnight={false}
                  contextLabel={accountLabel}
                />
              </div>

              <div className="ic-Form-control">
                <label id="end-date-label" htmlFor="end-date" className="ic-Label">
                  {I18n.t('End Date')}
                </label>
                <DueDateCalendarPicker
                  disabled={false}
                  inputClasses=""
                  dateValue={this.state.period.endDate}
                  dateType="due_at"
                  handleUpdate={this.changeEndDate}
                  rowKey="end-date"
                  labelledBy="end-date-label"
                  isFancyMidnight={true}
                  defaultToEndOfMinute={true}
                  contextLabel={accountLabel}
                />
              </div>

              <div className="ic-Form-control">
                <label id="close-date-label" htmlFor="close-date" className="ic-Label">
                  {I18n.t('Close Date')}
                </label>
                <DueDateCalendarPicker
                  disabled={false}
                  inputClasses=""
                  dateValue={this.state.period.closeDate}
                  dateType="due_at"
                  handleUpdate={this.changeCloseDate}
                  rowKey="close-date"
                  labelledBy="close-date-label"
                  isFancyMidnight={true}
                  defaultToEndOfMinute={true}
                  contextLabel={accountLabel}
                />
              </div>

              {this.renderWeightInput()}
            </div>
          </div>
        </div>

        {this.renderSaveAndCancelButtons()}
      </div>
    )
  }
}

export default GradingPeriodForm
