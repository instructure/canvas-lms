/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import update from 'immutability-helper'
import GradingPeriod from './gradingPeriod'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {map, isEmpty, every, find, reject, some} from 'lodash'
import {camelizeProperties} from '@canvas/convert-case'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('gradinggradingPeriodCollection')

const periodsAreLoaded = state => state.periods !== null

class GradingPeriodCollection extends React.Component {
  static propTypes = {
    // no props
  }

  state = {
    periods: null,
    readOnly: false,
    disabled: false,
    saveDisabled: true,
  }

  UNSAFE_componentWillMount() {
    this.getPeriods()
  }

  getPeriods = () => {
    const self = this
    $.getJSON(ENV.GRADING_PERIODS_URL)
      .success(periods => {
        self.setState({
          periods: self.deserializePeriods(periods),
          readOnly: periods.grading_periods_read_only,
          disabled: false,
          saveDisabled: isEmpty(periods.grading_periods),
        })
      })
      .error(() => {
        $.flashError(I18n.t('There was a problem fetching periods'))
      })
  }

  deserializePeriods = periods =>
    map(periods.grading_periods, period => {
      const newPeriod = camelizeProperties(period)
      newPeriod.startDate = new Date(period.start_date)
      newPeriod.endDate = new Date(period.end_date)
      newPeriod.closeDate = new Date(period.close_date || period.end_date)
      return newPeriod
    })

  deleteGradingPeriod = id => {
    if (id.indexOf('new') > -1) {
      this.removeDeletedGradingPeriod(id)
    } else {
      const self = this
      $(`#grading-period-${id}`).confirmDelete({
        url: `${ENV.GRADING_PERIODS_URL}/${id}`,
        message: I18n.t('Are you sure you want to delete this grading period?'),
        success() {
          $.flashMessage(I18n.t('The grading period was deleted'))
          if (self.lastRemainingPeriod()) {
            self.getPeriods()
          } else {
            self.removeDeletedGradingPeriod(id)
          }
        },
        error() {
          $.flashError(I18n.t('There was a problem deleting the grading period'))
        },
      })
    }
  }

  lastRemainingPeriod = () => this.state.periods.length === 1

  removeDeletedGradingPeriod = id => {
    const newPeriods = reject(this.state.periods, period => period.id === id)
    this.setState({periods: newPeriods})
  }

  getPeriodById = id => find(this.state.periods, period => period.id === id)

  areGradingPeriodsValid = () =>
    every(
      this.state.periods,
      period =>
        this.isTitleCompleted(period) &&
        this.areDatesValid(period) &&
        this.isStartDateBeforeEndDate(period) &&
        this.areNoDatesOverlapping(period)
    )

  areDatesOverlapping = targetPeriod => {
    const target = this.getPeriodById(targetPeriod.id)
    const otherPeriods = reject(this.state.periods, p => p.id === target.id)
    if (isEmpty(otherPeriods)) return false
    return some(
      otherPeriods,
      period =>
        // http://c2.com/cgi/wiki?TestIfDateRangesOverlap
        target.startDate < period.endDate && period.startDate < target.endDate
    )
  }

  areNoDatesOverlapping = targetPeriod => {
    if (this.areDatesOverlapping(targetPeriod)) {
      $.flashError(I18n.t('Grading periods must not overlap'))
      return false
    } else {
      return true
    }
  }

  areDatesValid = period => {
    if (!Number.isNaN(Number(period.startDate)) && !Number.isNaN(Number(period.endDate))) {
      return true
    } else {
      $.flashError(I18n.t('All dates fields must be present and formatted correctly'))
      return false
    }
  }

  isStartDateBeforeEndDate = period => {
    if (period.startDate < period.endDate) {
      return true
    } else {
      $.flashError(I18n.t('All start dates must be before the end date'))
      return false
    }
  }

  isTitleCompleted = period => {
    if (period.title.trim().length > 0) {
      return true
    } else {
      $.flashError(I18n.t('All grading periods must have a title'))
      return false
    }
  }

  updateGradingPeriodCollection = updatedGradingPeriodComponent => {
    const attrs = $.extend(
      true,
      {},
      updatedGradingPeriodComponent.props,
      updatedGradingPeriodComponent.state
    )
    const existingGradingPeriod = this.getPeriodById(attrs.id)
    const indexToUpdate = this.state.periods.indexOf(existingGradingPeriod)
    const updatedPeriods = update(this.state.periods, {$splice: [[indexToUpdate, 1, attrs]]})
    this.setState({periods: updatedPeriods})
  }

  serializeDataForSubmission = () => {
    const periods = map(this.state.periods, period => ({
      id: period.id,
      title: period.title,
      start_date: period.startDate,
      end_date: period.endDate,
    }))
    return {grading_periods: periods}
  }

  batchUpdatePeriods = () => {
    this.setState({disabled: true}, () => {
      if (this.areGradingPeriodsValid()) {
        $.ajax({
          type: 'PATCH',
          url: `${ENV.GRADING_PERIODS_URL}/batch_update`,
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(this.serializeDataForSubmission()),
          context: this,
        })
          .success(function (response) {
            $.flashMessage(I18n.t('All changes were saved'))
            this.setState({disabled: false, periods: this.deserializePeriods(response)})
          })
          .error(function (_error) {
            this.setState({disabled: false})
            $.flashError(I18n.t('There was a problem saving the grading period'))
          })
      } else {
        this.setState({disabled: false})
      }
    })
  }

  renderSaveButton = () => {
    if (
      periodsAreLoaded(this.state) &&
      !this.state.readOnly &&
      every(this.state.periods, period => period.permissions.update)
    ) {
      return (
        <div className="form-actions">
          <button
            className="Button btn-primary btn save_button"
            type="button"
            id="update-button"
            disabled={this.state.disabled || this.state.saveDisabled}
            onClick={this.batchUpdatePeriods}
          >
            {this.state.disabled ? I18n.t('Updating') : I18n.t('Save')}
          </button>
        </div>
      )
    }
  }

  renderGradingPeriods = () => {
    if (!this.state.periods) return null
    return map(this.state.periods, period => (
      <GradingPeriod
        key={period.id}
        ref={`grading_period_${period.id}`}
        id={period.id}
        title={period.title}
        startDate={period.startDate}
        endDate={period.endDate}
        closeDate={period.closeDate}
        permissions={period.permissions}
        readOnly={this.state.readOnly}
        disabled={this.state.disabled}
        weight={period.weight}
        weighted={ENV.GRADING_PERIODS_WEIGHTED}
        updateGradingPeriodCollection={this.updateGradingPeriodCollection}
        onDeleteGradingPeriod={this.deleteGradingPeriod}
      />
    ))
  }

  render() {
    return (
      <div>
        <div id="grading_periods" className="content-box">
          {this.renderGradingPeriods()}
        </div>
        {this.renderSaveButton()}
      </div>
    )
  }
}

export default GradingPeriodCollection
