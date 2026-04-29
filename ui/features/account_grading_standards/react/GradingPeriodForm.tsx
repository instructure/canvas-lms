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
import ReactDOM from 'react-dom'
import update from 'immutability-helper'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'
import numberHelper from '@canvas/i18n/numberHelper'
import round from '@canvas/round'
import {isEqual} from 'es-toolkit/compat'
import type {GradingPeriodDraft} from './types'

const I18n = createI18nScope('gradingPeriodForm')

interface GradingPeriodFormProps {
  period?: Partial<GradingPeriodDraft>
  weighted: boolean
  disabled: boolean
  onSave: (period: GradingPeriodDraft) => void
  onCancel: () => void
}

interface GradingPeriodFormState {
  period: GradingPeriodDraft
  preserveCloseDate: boolean
}

function roundWeight(val: unknown): number | null {
  const value = numberHelper.parse(typeof val === 'number' ? val : String(val ?? ''))
  return Number.isNaN(value) ? null : round(value, 2)
}

function buildPeriod(attr: Partial<GradingPeriodDraft> = {}): GradingPeriodDraft {
  return {
    id: attr.id,
    title: attr.title ?? '',
    weight: roundWeight(attr.weight),
    startDate: attr.startDate ?? null,
    endDate: attr.endDate ?? null,
    closeDate: attr.closeDate ?? null,
  }
}

class GradingPeriodForm extends React.Component<GradingPeriodFormProps, GradingPeriodFormState> {
  private titleRef: HTMLInputElement | null = null

  constructor(props: GradingPeriodFormProps) {
    super(props)
    const period = buildPeriod(props.period ?? {})

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
    this.props.onSave(this.state.period)
  }

  triggerCancel = () => {
    this.setState({period: buildPeriod({})}, this.props.onCancel)
  }

  hasDistinctCloseDate = ({
    endDate,
    closeDate,
  }: Pick<GradingPeriodDraft, 'endDate' | 'closeDate'>) =>
    !!closeDate && !isEqual(endDate, closeDate)

  mergePeriod = (attr: Partial<GradingPeriodDraft>) => update(this.state.period, {$merge: attr})

  changeTitle = (e: React.ChangeEvent<HTMLInputElement>) => {
    const period = this.mergePeriod({title: e.target.value})
    this.setState({period})
  }

  changeWeight = (e: React.ChangeEvent<HTMLInputElement>) => {
    const period = this.mergePeriod({weight: roundWeight(e.target.value)})
    this.setState({period})
  }

  changeStartDate = (date: Date | null) => {
    const period = this.mergePeriod({startDate: date})
    this.setState({period})
  }

  changeEndDate = (date: Date | null) => {
    const attr: Partial<GradingPeriodDraft> = {endDate: date}
    if (!this.state.preserveCloseDate && !this.hasDistinctCloseDate(this.state.period)) {
      attr.closeDate = date
    }
    const period = this.mergePeriod(attr)
    this.setState({period})
  }

  changeCloseDate = (date: Date | null) => {
    const period = this.mergePeriod({closeDate: date})
    this.setState({period, preserveCloseDate: !!date})
  }

  hackTheDatepickers = () => {
    // This can be replaced when we have an extensible datepicker
    const formNode = ReactDOM.findDOMNode(this)
    if (!(formNode instanceof HTMLElement)) return

    const appends = formNode.querySelectorAll<HTMLElement>('.input-append')
    appends.forEach(el => {
      el.classList.add('ic-Input-group')
    })

    const dateFields = formNode.querySelectorAll<HTMLElement>('.date_field')
    dateFields.forEach(el => {
      el.classList.remove('date_field')
      el.classList.add('ic-Input')
    })

    const buttons = formNode.querySelectorAll<HTMLElement>('.ui-datepicker-trigger')
    buttons.forEach(el => {
      el.classList.remove('btn')
      el.classList.add('Button')
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
            defaultValue={this.state.period.weight == null ? '' : I18n.n(this.state.period.weight)}
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
