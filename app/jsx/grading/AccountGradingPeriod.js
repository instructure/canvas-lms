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
import Button from '@instructure/ui-buttons/lib/components/Button'
import axios from 'axios'
import I18n from 'i18n!grading_periods'
import tz from 'timezone'
import DateHelper from '../shared/helpers/dateHelper'
import 'jquery.instructure_misc_helpers'

class AccountGradingPeriod extends React.Component {
  static propTypes = {
    period: PropTypes.shape({
      id: PropTypes.string.isRequired,
      title: PropTypes.string.isRequired,
      weight: PropTypes.number,
      startDate: PropTypes.instanceOf(Date).isRequired,
      endDate: PropTypes.instanceOf(Date).isRequired,
      closeDate: PropTypes.instanceOf(Date).isRequired
    }).isRequired,
    weighted: PropTypes.bool,
    onEdit: PropTypes.func.isRequired,
    actionsDisabled: PropTypes.bool,
    readOnly: PropTypes.bool.isRequired,
    permissions: PropTypes.shape({
      read: PropTypes.bool.isRequired,
      create: PropTypes.bool.isRequired,
      update: PropTypes.bool.isRequired,
      delete: PropTypes.bool.isRequired
    }).isRequired,
    onDelete: PropTypes.func.isRequired,
    deleteGradingPeriodURL: PropTypes.string.isRequired
  }

  promptDeleteGradingPeriod = event => {
    event.stopPropagation()
    const confirmMessage = I18n.t('Are you sure you want to delete this grading period?')
    if (!window.confirm(confirmMessage)) return null
    const url = $.replaceTags(this.props.deleteGradingPeriodURL, 'id', this.props.period.id)

    axios
      .delete(url)
      .then(() => {
        $.flashMessage(I18n.t('The grading period was deleted'))
        this.props.onDelete(this.props.period.id)
      })
      .catch(() => {
        $.flashError(I18n.t('An error occured while deleting the grading period'))
      })
  }

  onEdit = e => {
    e.stopPropagation()
    this.props.onEdit(this.props.period)
  }

  renderEditButton = () => {
    if (this.props.permissions.update && !this.props.readOnly) {
      return (
        <Button
          ref="editButton"
          variant="icon"
          disabled={this.props.actionsDisabled}
          onClick={this.onEdit}
          title={I18n.t('Edit %{title}', {title: this.props.period.title})}
        >
          <span className="screenreader-only">
            {I18n.t('Edit %{title}', {title: this.props.period.title})}
          </span>
          <i className="icon-edit" role="presentation" />
        </Button>
      )
    }
  }

  renderDeleteButton = () => {
    if (this.props.permissions.delete && !this.props.readOnly) {
      return (
        <Button
          ref="deleteButton"
          variant="icon"
          disabled={this.props.actionsDisabled}
          onClick={this.promptDeleteGradingPeriod}
          title={I18n.t('Delete %{title}', {title: this.props.period.title})}
        >
          <span className="screenreader-only">
            {I18n.t('Delete %{title}', {title: this.props.period.title})}
          </span>
          <i className="icon-trash" role="presentation" />
        </Button>
      )
    }
  }

  renderWeight = () => {
    if (this.props.weighted) {
      return (
        <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-2">
          <span ref="weight">
            {I18n.t('Weight:')} {I18n.n(this.props.period.weight, {percentage: true})}
          </span>
        </div>
      )
    }
  }

  render() {
    return (
      <div className="GradingPeriodList__period">
        <div className="GradingPeriodList__period__attributes grid-row">
          <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
            <span ref="title">{this.props.period.title}</span>
          </div>
          <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-2">
            <span ref="startDate">
              {I18n.t('Starts:')} {DateHelper.formatDateForDisplay(this.props.period.startDate)}
            </span>
          </div>
          <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-2">
            <span ref="endDate">
              {I18n.t('Ends:')} {DateHelper.formatDateForDisplay(this.props.period.endDate)}
            </span>
          </div>
          <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-2">
            <span ref="closeDate">
              {I18n.t('Closes:')} {DateHelper.formatDateForDisplay(this.props.period.closeDate)}
            </span>
          </div>
          {this.renderWeight()}
        </div>
        <div className="GradingPeriodList__period__actions">
          {this.renderEditButton()}
          {this.renderDeleteButton()}
        </div>
      </div>
    )
  }
}

export default AccountGradingPeriod
