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

import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconPlusLine} from '@instructure/ui-icons'
import {NewKeyButtons} from './NewKeyButtons'

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

  triggerButton() {
    return (
      <Button
        data-heap="add-developer-key-button"
        color="primary"
        elementRef={this.props.setAddKeyButtonRef}
        renderIcon={IconPlusLine}
      >
        <ScreenReaderContent>{I18n.t('Create a')}</ScreenReaderContent>
        {I18n.t('Developer Key')}
      </Button>
    )
  }

  developerKeyTrigger() {
    return (
      <NewKeyButtons
        triggerButton={this.triggerButton()}
        showCreateDeveloperKey={this.showCreateDeveloperKey}
        showCreateLtiKey={this.showCreateLtiKey}
      />
    )
  }

  render() {
    return (
      <View as="div" padding="small" textAlign="end">
        {this.developerKeyTrigger()}
      </View>
    )
  }
}

DeveloperKeyModalTrigger.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    developerKeysModalOpen: PropTypes.func.isRequired,
    ltiKeysSetLtiKey: PropTypes.func.isRequired,
  }).isRequired,
  setAddKeyButtonRef: PropTypes.func.isRequired,
}
