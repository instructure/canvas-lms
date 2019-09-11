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

import {Flex, View} from '@instructure/ui-layout'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {IconPlusLine} from '@instructure/ui-icons'

import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'

export default class DeveloperKeyModalTrigger extends React.Component {
  showCreateDeveloperKey = () => {
    this.props.store.dispatch(this.props.actions.developerKeysModalOpen('api'))
  }

  showCreateLtiKey = () => {
    this.props.store.dispatch(this.props.actions.ltiKeysSetLtiKey(true))
    this.props.store.dispatch(this.props.actions.developerKeysModalOpen('lti'))
  }

  developerKeyMenuItem(title, onClick) {
    return (
      <Menu.Item onClick={onClick} type="button">
        <Flex>
          <Flex.Item padding="0 x-small 0 0" margin="0 0 xxx-small 0">
            <IconPlusLine />
          </Flex.Item>
          <Flex.Item>
            <ScreenReaderContent>{I18n.t('Create an')}</ScreenReaderContent>
            {title}
          </Flex.Item>
        </Flex>
      </Menu.Item>
    )
  }

  triggerButton() {
    return (
      <Button
        variant="primary"
        buttonRef={this.props.setAddKeyButtonRef}
        icon={IconPlusLine}
      >
        <ScreenReaderContent>{I18n.t('Create a')}</ScreenReaderContent>
        {I18n.t('Developer Key')}
      </Button>
    )
  }

  developerKeyTrigger() {
    return (
      <Menu placement="bottom" trigger={this.triggerButton()} shouldHideOnSelect>
        {this.developerKeyMenuItem(I18n.t('API Key'), this.showCreateDeveloperKey)}
        {this.developerKeyMenuItem(I18n.t('LTI Key'), this.showCreateLtiKey)}
      </Menu>
    )
  }

  render() {
    return (
      <View as="div" margin="0 0 small 0" padding="none" textAlign="end">
        {this.developerKeyTrigger()}
      </View>
    )
  }
}

DeveloperKeyModalTrigger.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired
  }).isRequired,
  actions: PropTypes.shape({
    developerKeysModalOpen: PropTypes.func.isRequired,
    ltiKeysSetLtiKey: PropTypes.func.isRequired
  }).isRequired,
  setAddKeyButtonRef: PropTypes.func.isRequired
}
