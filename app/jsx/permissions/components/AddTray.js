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

import I18n from 'i18n!permissions_v2_add_tray'

import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import React, {Component} from 'react'

import {COURSE} from '../propTypes'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-layout/lib/components/View'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import IconX from '@instructure/ui-icons/lib/Solid/IconX'
import Text from '@instructure/ui-elements/lib/components/Text'
import Select from '@instructure/ui-core/lib/components/Select'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'

import actions from '../actions'

import {roleIsCourseBaseRole} from '../helper/utils'

export default class AddTray extends Component {
  static propTypes = {
    allBaseRoles: PropTypes.arrayOf(PropTypes.object).isRequired,
    allLabels: PropTypes.arrayOf(PropTypes.string).isRequired,
    hideTray: PropTypes.func.isRequired,
    createNewRole: PropTypes.func.isRequired,
    open: PropTypes.bool.isRequired,
    loading: PropTypes.bool.isRequired,
    tab: PropTypes.string.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''},
      roleNameErrors: []
    }
  }

  componentWillReceiveProps(newProps) {
    if (!this.props.loading) {
      this.setState({
        selectedRoleName: '',
        selectedBaseType: newProps.allBaseRoles[0] || {label: ''},
        roleNameErrors: []
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
      roleNameErrors: errorMessages
    })
  }

  onChangeBaseType = event => {
    const foundRole = this.props.allBaseRoles.find(element => element.label === event.target.value)
    this.setState({
      selectedBaseType: foundRole
    })
  }

  hideTray = () => {
    this.setState({
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''},
      roleNameErrors: []
    })
    this.props.hideTray()
  }

  handleSaveButton = () => {
    const newRole = this.state.selectedBaseType
    newRole.base_role_type =
      this.props.tab === COURSE ? newRole.base_role_type : 'AccountMembership'
    const context = this.props.tab === COURSE ? 'Course' : 'Account'
    this.props.createNewRole(this.state.selectedRoleName, newRole, context)
  }

  isDoneSelecting = () => !!this.state.selectedRoleName

  renderTrayHeader = () => (
    <Flex alignItems="center" margin="small">
      <FlexItem>
        <Button
          variant="icon"
          size="small"
          onClick={this.hideTray}
          buttonRef={c => (this.closeButton = c)}
        >
          <IconX title={I18n.t('Close')} />
        </Button>
      </FlexItem>
      <FlexItem>
        <Container as="div" margin="0 0 0 small">
          <Heading level="h3" as="h2">
            {this.props.tab === COURSE ? I18n.t('New Course Role') : I18n.t('New Account Role')}
          </Heading>
        </Container>
      </FlexItem>
    </Flex>
  )

  renderSelectRoleName = () => (
    <Container display="block" margin="medium 0">
      <TextInput
        onChange={this.onChangeRoleName}
        id="add_role_input"
        value={this.state.selectedRoleName}
        label={<Text weight="light">{`${I18n.t('Role Name')}:`}</Text>}
        messages={this.state.roleNameErrors}
      />
    </Container>
  )

  renderSelectBaseRole = () => (
    <Container display="block" margin="medium 0">
      <Select
        onChange={this.onChangeBaseType}
        value={this.state.selectedBaseType.label}
        label={<Text weight="light">{`${I18n.t('Base Type')}:`}</Text>}
      >
        {this.props.allBaseRoles.map(item => (
          <option key={item.label} value={item.label}>
            {item.label}
          </option>
        ))}
      </Select>
    </Container>
  )

  renderTrayFooter() {
    return (
      <div className="permissions__add-tray-footer">
        <Container textAlign="end" display="block">
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
            disabled={!this.isDoneSelecting() || this.state.roleNameErrors.length !== 0}
            type="submit"
            variant="primary"
            onClick={this.handleSaveButton}
            margin="0 x-small 0 0"
          >
            {I18n.t('Save')}
          </Button>
        </Container>
      </div>
    )
  }

  renderLoadingIndicator() {
    return (
      <Container display="block" margin="auto">
        <Spinner size="large" title={I18n.t('Saving New Role')} />
      </Container>
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
          <Container>
            <Container as="div" padding="small small x-large small">
              {this.renderSelectRoleName()}
              {this.props.tab === COURSE && this.renderSelectBaseRole()}
            </Container>
            {this.renderTrayFooter()}
          </Container>
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
      tab: COURSE
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
    tab: state.roles.find(role => !!role.displayed).contextType
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  createNewRole: actions.createNewRole,
  hideTray: actions.hideAllTrays
}

export const ConnectedAddTray = connect(
  mapStateToProps,
  mapDispatchToProps
)(AddTray)
