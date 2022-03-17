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

import {View} from '@instructure/ui-view'

import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconPlusLine} from '@instructure/ui-icons'

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

const I18n = useI18nScope('react_developer_keys')

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
      <Button color="primary" elementRef={this.props.setAddKeyButtonRef} renderIcon={IconPlusLine}>
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
