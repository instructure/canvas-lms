/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import actions from '../actions'
import {connect} from 'react-redux'
import {COURSE} from '@canvas/permissions/react/propTypes'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {Component} from 'react'
import {roleIsCourseBaseRole} from '@canvas/permissions/util'
import {Button, IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {IconXSolid} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Tray} from '@instructure/ui-tray'

const I18n = useI18nScope('permissions_v2_add_tray')

export default class AddTray extends Component {
  static propTypes = {
    allBaseRoles: PropTypes.arrayOf(PropTypes.object).isRequired,
    allLabels: PropTypes.arrayOf(PropTypes.string),
    hideTray: PropTypes.func.isRequired,
    createNewRole: PropTypes.func.isRequired,
    open: PropTypes.bool.isRequired,
    loading: PropTypes.bool.isRequired,
    tab: PropTypes.string.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''},
      roleNameErrors: [],
    }
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    if (!this.props.loading) {
      this.setState({
        selectedRoleName: '',
        selectedBaseType: newProps.allBaseRoles[0] || {label: ''},
        roleNameErrors: [],
      })
    }
  }

  onChangeRoleName = event => {
    const trimmedValue = event.target.value.trim()
    let errorMessages = []
    if (this.props.allLabels.includes(trimmedValue)) {
      const err = I18n.t('Cannot add role name %{name}: already in use', {name: trimmedValue})
      errorMessages = [{text: err, type: 'error'}]
    }

    this.setState({
      selectedRoleName: event.target.value,
      roleNameErrors: errorMessages,
    })
  }

  onChangeBaseType = event => {
    const foundRole = this.props.allBaseRoles.find(element => element.label === event.target.value)
    this.setState({
      selectedBaseType: foundRole,
    })
  }

  hideTray = () => {
    this.setState({
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''},
      roleNameErrors: [],
    })
    this.props.hideTray()
  }

  handleSaveButton = () => {
    if (this.state.selectedRoleName.length === 0) {
      const roleNameErrors = [{type: 'error', text: I18n.t('A role name is required')}]
      this.setState({roleNameErrors})
      return
    }
    const newRole = this.state.selectedBaseType
    newRole.base_role_type =
      this.props.tab === COURSE ? newRole.base_role_type : 'AccountMembership'
    const context = this.props.tab === COURSE ? 'Course' : 'Account'
    this.props.createNewRole(this.state.selectedRoleName, newRole, context)
  }

  renderTrayHeader = () => (
    <Flex alignItems="center" margin="small">
      <Flex.Item>
        <IconButton
          id="close-add-role-tray-button"
          size="small"
          onClick={this.hideTray}
          elementRef={c => (this.closeButton = c)}
          screenReaderLabel={I18n.t('Close')}
        >
          <IconXSolid />
        </IconButton>
      </Flex.Item>
      <Flex.Item>
        <View as="div" margin="0 0 0 small">
          <Heading level="h3" as="h2">
            {this.props.tab === COURSE ? I18n.t('New Course Role') : I18n.t('New Account Role')}
          </Heading>
        </View>
      </Flex.Item>
    </Flex>
  )

  renderSelectRoleName = () => (
    <View display="block" margin="medium 0">
      <TextInput
        isRequired={true}
        onChange={this.onChangeRoleName}
        id="add_role_input"
        value={this.state.selectedRoleName}
        renderLabel={<Text weight="light">{`${I18n.t('Role Name')}:`}</Text>}
        messages={this.state.roleNameErrors}
      />
    </View>
  )

  renderSelectBaseRole = () => (
    <View display="block" margin="medium 0">
      <FormField id="add-tray" label={<Text weight="light">{`${I18n.t('Base Type')}:`}</Text>}>
        <select
          onChange={this.onChangeBaseType}
          style={{
            margin: '0',
            width: '100%',
          }}
          value={this.state.selectedBaseType.label}
        >
          {this.props.allBaseRoles.map(item => (
            <option key={item.label} value={item.label}>
              {item.label}
            </option>
          ))}
        </select>
      </FormField>
    </View>
  )

  renderTrayFooter() {
    return (
      <div className="permissions__add-tray-footer">
        <View textAlign="end" display="block">
          <hr aria-hidden="true" />
          <Button
            id="permissions-add-tray-cancel-button"
            onClick={this.props.hideTray}
            margin="0 x-small 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            id="permissions-add-tray-submit-button"
            disabled={this.state.roleNameErrors.length !== 0}
            type="submit"
            color="primary"
            onClick={this.handleSaveButton}
            margin="0 x-small 0 0"
          >
            {I18n.t('Save')}
          </Button>
        </View>
      </div>
    )
  }

  renderLoadingIndicator() {
    return (
      <View display="block" margin="auto">
        <Spinner size="large" renderTitle={I18n.t('Saving New Role')} />
      </View>
    )
  }

  render() {
    return (
      <Tray
        label={I18n.t('New Course Role')}
        open={this.props.open}
        onDismiss={this.hideTray}
        size="small"
        placement="end"
      >
        {this.renderTrayHeader()}
        {this.props.loading ? (
          this.renderLoadingIndicator()
        ) : (
          <View>
            <View as="div" padding="small small x-large small">
              {this.renderSelectRoleName()}
              {this.props.tab === COURSE && this.renderSelectBaseRole()}
            </View>
            {this.renderTrayFooter()}
          </View>
        )}
      </Tray>
    )
  }
}

export function mapStateToProps(state, ownProps) {
  if (state.activeAddTray && !state.activeAddTray.show) {
    const stateProps = {
      allBaseRoles: [],
      open: false,
      loading: false,
      tab: COURSE,
    }
    return {...stateProps, ...ownProps}
  }

  const allBaseRoles = state.roles.reduce((acc, r) => {
    if (roleIsCourseBaseRole(r)) {
      acc.push(r)
    }
    return acc
  }, [])

  const stateProps = {
    allBaseRoles,
    allLabels: state.roles.map(r => r.label),
    open: true,
    loading: state.activeAddTray && state.activeAddTray.loading,
    tab: state.roles.find(role => !!role.displayed).contextType,
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  createNewRole: actions.createNewRole,
  hideTray: actions.hideAllTrays,
}

export const ConnectedAddTray = connect(mapStateToProps, mapDispatchToProps)(AddTray)
