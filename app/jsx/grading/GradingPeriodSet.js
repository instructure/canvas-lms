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
import $ from 'jquery'
import _ from 'underscore'
import Button from '@instructure/ui-buttons/lib/components/Button'
import axios from 'axios'
import I18n from 'i18n!grading_periods'
import GradingPeriod from '../grading/AccountGradingPeriod'
import GradingPeriodForm from '../grading/GradingPeriodForm'
import gradingPeriodsApi from 'compiled/api/gradingPeriodsApi'
import 'jquery.instructure_misc_helpers'

const sortPeriods = function(periods) {
  return _.sortBy(periods, 'startDate')
}

const anyPeriodsOverlap = function(periods) {
  if (_.isEmpty(periods)) {
    return false
  }
  const firstPeriod = _.first(periods)
  const otherPeriods = _.rest(periods)
  const overlapping = _.some(
    otherPeriods,
    otherPeriod =>
      otherPeriod.startDate < firstPeriod.endDate && firstPeriod.startDate < otherPeriod.endDate
  )
  return overlapping || anyPeriodsOverlap(otherPeriods)
}

const isValidDate = function(date) {
  return Object.prototype.toString.call(date) === '[object Date]' && !isNaN(date.getTime())
}

const validatePeriods = function(periods, weighted) {
  if (_.any(periods, period => !(period.title || '').trim())) {
    return [I18n.t('All grading periods must have a title')]
  }

  if (weighted && _.any(periods, period => isNaN(period.weight) || period.weight < 0)) {
    return [I18n.t('All weights must be greater than or equal to 0')]
  }

  const validDates = _.all(
    periods,
    period =>
      isValidDate(period.startDate) && isValidDate(period.endDate) && isValidDate(period.closeDate)
  )

  if (!validDates) {
    return [I18n.t('All dates fields must be present and formatted correctly')]
  }

  const orderedStartAndEndDates = _.all(periods, period => period.startDate < period.endDate)

  if (!orderedStartAndEndDates) {
    return [I18n.t('All start dates must be before the end date')]
  }

  const orderedEndAndCloseDates = _.all(periods, period => period.endDate <= period.closeDate)

  if (!orderedEndAndCloseDates) {
    return [I18n.t('All close dates must be on or after the end date')]
  }

  if (anyPeriodsOverlap(periods)) {
    return [I18n.t('Grading periods must not overlap')]
  }
}

const isEditingPeriod = function(state) {
  return !!state.editPeriod.id
}

const isActionsDisabled = function(state, props) {
  return !!(props.actionsDisabled || isEditingPeriod(state) || state.newPeriod.period)
}

const getShowGradingPeriodRef = function(period) {
  return `show-grading-period-${period.id}`
}

const getEditGradingPeriodRef = function(period) {
  return `edit-grading-period-${period.id}`
}

const {shape, number, string, array, bool, func} = PropTypes

class GradingPeriodSet extends React.Component {
  static propTypes = {
    gradingPeriods: array.isRequired,
    terms: array.isRequired,
    readOnly: bool.isRequired,
    expanded: bool,
    actionsDisabled: bool,
    onEdit: func.isRequired,
    onDelete: func.isRequired,
    onPeriodsChange: func.isRequired,
    onToggleBody: func.isRequired,

    set: shape({
      id: string.isRequired,
      title: string.isRequired,
      weighted: bool,
      displayTotalsForAllGradingPeriods: bool.isRequired
    }).isRequired,

    urls: shape({
      batchUpdateURL: string.isRequired,
      deleteGradingPeriodURL: string.isRequired,
      gradingPeriodSetsURL: string.isRequired
    }).isRequired,

    permissions: shape({
      read: bool.isRequired,
      create: bool.isRequired,
      update: bool.isRequired,
      delete: bool.isRequired
    }).isRequired
  }

  state = {
    title: this.props.set.title,
    weighted: !!this.props.set.weighted,
    displayTotalsForAllGradingPeriods: this.props.set.displayTotalsForAllGradingPeriods,
    gradingPeriods: sortPeriods(this.props.gradingPeriods),
    newPeriod: {
      period: null,
      saving: false
    },
    editPeriod: {
      id: null,
      saving: false
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.newPeriod.period && !this.state.newPeriod.period) {
      this.refs.addPeriodButton.focus()
    } else if (isEditingPeriod(prevState) && !isEditingPeriod(this.state)) {
      const period = {id: prevState.editPeriod.id}
      this.refs[getShowGradingPeriodRef(period)].refs.editButton.focus()
    }
  }

  toggleSetBody = () => {
    if (!isEditingPeriod(this.state)) {
      this.props.onToggleBody()
    }
  }

  promptDeleteSet = event => {
    event.stopPropagation()
    const confirmMessage = I18n.t('Are you sure you want to delete this grading period set?')
    if (!window.confirm(confirmMessage)) return null

    const url = `${this.props.urls.gradingPeriodSetsURL}/${this.props.set.id}`
    axios
      .delete(url)
      .then(() => {
        $.flashMessage(I18n.t('The grading period set was deleted'))
        this.props.onDelete(this.props.set.id)
      })
      .catch(() => {
        $.flashError(I18n.t('An error occured while deleting the grading period set'))
      })
  }

  setTerms = () => _.where(this.props.terms, {gradingPeriodGroupId: this.props.set.id})

  termNames = () => {
    const names = _.pluck(this.setTerms(), 'displayName')
    if (names.length > 0) {
      return I18n.t('Terms: ') + names.join(', ')
    } else {
      return I18n.t('No Associated Terms')
    }
  }

  editSet = e => {
    e.stopPropagation()
    this.props.onEdit(this.props.set)
  }

  changePeriods = periods => {
    const sortedPeriods = sortPeriods(periods)
    this.setState({gradingPeriods: sortedPeriods})
    this.props.onPeriodsChange(this.props.set.id, sortedPeriods)
  }

  removeGradingPeriod = idToRemove => {
    const periods = _.reject(this.state.gradingPeriods, period => period.id === idToRemove)
    this.setState({gradingPeriods: periods})
  }

  showNewPeriodForm = () => {
    this.setNewPeriod({period: {}})
  }

  saveNewPeriod = period => {
    const periods = this.state.gradingPeriods.concat([period])
    const validations = validatePeriods(periods, this.state.weighted)
    if (_.isEmpty(validations)) {
      this.setNewPeriod({saving: true})
      gradingPeriodsApi
        .batchUpdate(this.props.set.id, periods)
        .then(periods => {
          $.flashMessage(I18n.t('All changes were saved'))
          this.removeNewPeriodForm()
          this.changePeriods(periods)
        })
        .catch(_ => {
          $.flashError(I18n.t('There was a problem saving the grading period'))
          this.setNewPeriod({saving: false})
        })
    } else {
      _.each(validations, message => {
        $.flashError(message)
      })
    }
  }

  removeNewPeriodForm = () => {
    this.setNewPeriod({saving: false, period: null})
  }

  setNewPeriod = attr => {
    const period = $.extend(true, {}, this.state.newPeriod, attr)
    this.setState({newPeriod: period})
  }

  editPeriod = period => {
    this.setEditPeriod({id: period.id, saving: false})
  }

  updatePeriod = period => {
    const periods = _.reject(this.state.gradingPeriods, _period => period.id === _period.id).concat(
      [period]
    )
    const validations = validatePeriods(periods, this.state.weighted)
    if (_.isEmpty(validations)) {
      this.setEditPeriod({saving: true})
      gradingPeriodsApi
        .batchUpdate(this.props.set.id, periods)
        .then(periods => {
          $.flashMessage(I18n.t('All changes were saved'))
          this.setEditPeriod({id: null, saving: false})
          this.changePeriods(periods)
        })
        .catch(_ => {
          $.flashError(I18n.t('There was a problem saving the grading period'))
          this.setNewPeriod({saving: false})
        })
    } else {
      _.each(validations, message => {
        $.flashError(message)
      })
    }
  }

  cancelEditPeriod = () => {
    this.setEditPeriod({id: null, saving: false})
  }

  setEditPeriod = attr => {
    const period = $.extend(true, {}, this.state.editPeriod, attr)
    this.setState({editPeriod: period})
  }

  renderEditButton = () => {
    if (!this.props.readOnly && this.props.permissions.update) {
      const disabled = isActionsDisabled(this.state, this.props)
      return (
        <Button
          ref="editButton"
          variant="icon"
          disabled={disabled}
          onClick={this.editSet}
          title={I18n.t('Edit %{title}', {title: this.props.set.title})}
        >
          <span className="screenreader-only">
            {I18n.t('Edit %{title}', {title: this.props.set.title})}
          </span>
          <i className="icon-edit" />
        </Button>
      )
    }
  }

  renderDeleteButton = () => {
    if (!this.props.readOnly && this.props.permissions.delete) {
      const disabled = isActionsDisabled(this.state, this.props)
      return (
        <Button
          ref="deleteButton"
          variant="icon"
          disabled={disabled}
          onClick={this.promptDeleteSet}
          title={I18n.t('Delete %{title}', {title: this.props.set.title})}
        >
          <span className="screenreader-only">
            {I18n.t('Delete %{title}', {title: this.props.set.title})}
          </span>
          <i className="icon-trash" />
        </Button>
      )
    }
  }

  renderEditAndDeleteButtons = () => (
    <div className="ItemGroup__header__admin">
      {this.renderEditButton()}
      {this.renderDeleteButton()}
    </div>
  )

  renderSetBody = () => {
    if (!this.props.expanded) return null

    return (
      <div ref="setBody" className="ig-body">
        <div className="GradingPeriodList" ref="gradingPeriodList">
          {this.renderGradingPeriods()}
        </div>
        {this.renderNewPeriod()}
      </div>
    )
  }

  renderGradingPeriods = () => {
    const actionsDisabled = isActionsDisabled(this.state, this.props)
    return _.map(this.state.gradingPeriods, period => {
      if (period.id === this.state.editPeriod.id) {
        return (
          <div
            key={`edit-grading-period-${period.id}`}
            className="GradingPeriodList__period--editing pad-box"
          >
            <GradingPeriodForm
              ref="editPeriodForm"
              period={period}
              weighted={this.state.weighted}
              disabled={this.state.editPeriod.saving}
              onSave={this.updatePeriod}
              onCancel={this.cancelEditPeriod}
            />
          </div>
        )
      } else {
        return (
          <GradingPeriod
            key={`show-grading-period-${period.id}`}
            ref={getShowGradingPeriodRef(period)}
            period={period}
            weighted={this.state.weighted}
            actionsDisabled={actionsDisabled}
            onEdit={this.editPeriod}
            readOnly={this.props.readOnly}
            onDelete={this.removeGradingPeriod}
            deleteGradingPeriodURL={this.props.urls.deleteGradingPeriodURL}
            permissions={this.props.permissions}
          />
        )
      }
    })
  }

  renderNewPeriod = () => {
    if (this.props.permissions.create && !this.props.readOnly) {
      if (this.state.newPeriod.period) {
        return this.renderNewPeriodForm()
      } else {
        return this.renderNewPeriodButton()
      }
    }
  }

  renderNewPeriodButton = () => {
    const disabled = isActionsDisabled(this.state, this.props)
    return (
      <div className="GradingPeriodList__new-period center-xs border-rbl border-round-b">
        <Button
          variant="link"
          ref="addPeriodButton"
          disabled={disabled}
          aria-label={I18n.t('Add Grading Period')}
          onClick={this.showNewPeriodForm}
        >
          <i className="icon-plus GradingPeriodList__new-period__add-icon" />
          &nbsp;
          {I18n.t('Grading Period')}
        </Button>
      </div>
    )
  }

  renderNewPeriodForm = () => (
    <div className="GradingPeriodList__new-period--editing border border-rbl border-round-b pad-box">
      <GradingPeriodForm
        key="new-grading-period"
        ref="newPeriodForm"
        weighted={this.state.weighted}
        disabled={this.state.newPeriod.saving}
        onSave={this.saveNewPeriod}
        onCancel={this.removeNewPeriodForm}
      />
    </div>
  )

  render() {
    const setStateSuffix = this.props.expanded ? 'expanded' : 'collapsed'
    const arrow = this.props.expanded ? 'down' : 'right'
    return (
      <div className={`GradingPeriodSet--${setStateSuffix}`}>
        <div className="ItemGroup__header" ref="toggleSetBody" onClick={this.toggleSetBody}>
          <div>
            <div className="ItemGroup__header__title">
              <button
                className="Button Button--icon-action GradingPeriodSet__toggle"
                aria-expanded={this.props.expanded}
                aria-label={I18n.t('Toggle %{title} grading period visibility', {
                  title: this.props.set.title
                })}
              >
                <i className={`icon-mini-arrow-${arrow}`} />
              </button>
              <h2 ref="title" className="GradingPeriodSet__title">
                {this.props.set.title}
              </h2>
            </div>
            {this.renderEditAndDeleteButtons()}
          </div>
          <div className="EnrollmentTerms__list">{this.termNames()}</div>
        </div>
        {this.renderSetBody()}
      </div>
    )
  }
}

export default GradingPeriodSet
