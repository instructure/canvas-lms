/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_courses'
import React from 'react'
import PropTypes from 'prop-types'
import cx from 'classnames'

import Text from '@instructure/ui-elements/lib/components/Text'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import propTypes from '../propTypes'
import ExpandableLockOptions from './ExpandableLockOptions'
import LockCheckList from './LockCheckList'

const blueprintDescription = I18n.t('Enable course as a Blueprint Course')
const generalLocking = I18n.t('General Locked Objects')
const generalDescription = I18n.t('Define general settings for locked objects in this course. ')
const granularDescription = I18n.t('Define settings by type for locked objects in this course. ')
const standardDescription = I18n.t('Locked objects cannot be edited in associated courses.')
const granularLocking = I18n.t('Locked Objects by Type')
const granular = 'true'
const general = 'false'

const keys = [
  {objectType: 'assignment'},
  {objectType: 'discussion_topic'},
  {objectType: 'wiki_page',
    lockableAttributes: ['content']},
  {objectType: 'attachment',
    lockableAttributes: ['content']},
  {objectType: 'quiz'},
]

export default class BlueprintLockOptions extends React.Component {
  static propTypes = {
    isMasterCourse: PropTypes.bool.isRequired,
    disabledMessage: PropTypes.string,
    useRestrictionsbyType: PropTypes.bool.isRequired,
    generalRestrictions: propTypes.itemLocks.isRequired,
    restrictionsByType: propTypes.itemLocksByObject.isRequired,
    lockableAttributes: propTypes.lockableAttributeList,
  }

  static defaultProps = {
    disabledMessage: '',
    lockableAttributes: ['content', 'points', 'due_dates', 'availability_dates'],
  }

  constructor (props) {
    super(props)
    this.state = {
      lockType: props.useRestrictionsbyType ? granular : general,
      courseEnabled: props.isMasterCourse,
      generalRestrictions: props.generalRestrictions,
      objectRestrictions: props.restrictionsByType,
    }
  }

  onChange = (e) => {
    this.setState({
      lockType: e.target.value
    })
  }

  enableCourse = () => {
    this.setState({ courseEnabled: !this.state.courseEnabled })
  }

  renderGeneralMenu (lock) {
    const viewableClasses = cx({
      'bcs_sub-menu': true,
      'bcs_sub-menu-viewable': lock === general,
    })
    return (
      <div className={viewableClasses}>
        <div className="bcs_sub-menu-item">
          <Text size="x-small" lineHeight="condensed">{generalDescription + standardDescription}</Text>
        </div>
        <LockCheckList
          formName="[blueprint_restrictions]"
          lockableAttributes={this.props.lockableAttributes}
          locks={this.state.generalRestrictions}
        />
      </div>
    )
  }

  renderGranularMenu (lock) {
    const viewableClasses = cx({
      'bcs_sub-menu': true,
      'bcs_sub-menu-viewable': lock === granular,
    })
    return (
      <div className={viewableClasses}>
        <div className="bcs_sub-menu-item">
          <Text size="x-small">{granularDescription + standardDescription}</Text>
          {keys.map(item =>
            <ExpandableLockOptions
              key={item.objectType}
              objectType={item.objectType}
              locks={this.state.objectRestrictions[item.objectType]}
              lockableAttributes={item.lockableAttributes || this.props.lockableAttributes}
            />)}
        </div>
      </div>
    )
  }

  renderOptionMenu () {
    const viewableClasses = cx({
      'bcs_sub-menu': true,
      'bcs_sub-menu-viewable': this.state.courseEnabled,
    })
    return (
      <div className={viewableClasses}>
        <div className="blueprint_setting_options">
          <div className="bcs_radio_input-group">
            <RadioInput
              name="course[use_blueprint_restrictions_by_object_type]"
              label={generalLocking}
              value={general}
              onChange={this.onChange}
              checked={this.state.lockType === general}
            />
            {this.renderGeneralMenu(this.state.lockType)}
          </div>
          <div className="bcs_radio_input-group">
            <RadioInput
              ref={(c) => { this.granularRadioInput = c }}
              name="course[use_blueprint_restrictions_by_object_type]"
              label={granularLocking}
              value={granular}
              onChange={this.onChange}
              checked={this.state.lockType === granular}
            />
            {this.renderGranularMenu(this.state.lockType)}
          </div>
        </div>
      </div>
    )
  }

  render () {
    const disabled = !!this.props.disabledMessage
    let checkBox = (<div>
      <input type="hidden" name="course[blueprint]" value={false} />
      <Checkbox
        name="course[blueprint]"
        checked={this.state.courseEnabled}
        disabled={disabled}
        label={blueprintDescription}
        onChange={this.enableCourse}
        aria-label={this.props.disabledMessage}
        value="on"
      />
    </div>)
    if (disabled) {
      checkBox =
      (<div className="disabled_message">
        <Tooltip
          tip={this.props.disabledMessage}
          placement="top start"
          variant="inverse"
        >
          <div>{checkBox}</div>
        </Tooltip>
      </div>)
    }
    return (
      <div>
        <div className="bcs_check-box">{checkBox}</div>
        {this.renderOptionMenu()}
      </div>
    )
  }
}
