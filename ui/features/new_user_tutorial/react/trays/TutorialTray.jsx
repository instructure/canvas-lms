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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import plainStoreShape from '@canvas/util/react/proptypes/plainStoreShape'
import {Tray} from '@instructure/ui-tray'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import NewUserTutorialToggleButton from '../NewUserTutorialToggleButton'
import ConfirmEndTutorialDialog from '../ConfirmEndTutorialDialog'

const I18n = useI18nScope('new_user_tutorial')

class TutorialTray extends React.Component {
  static propTypes = {
    // Used as a label for the content (screenreader-only)
    label: PropTypes.string.isRequired,
    // The specific tray that will be wrapped, unusable without this.
    children: PropTypes.node.isRequired,
    // The store to control the status of everything
    store: PropTypes.shape(plainStoreShape).isRequired,
    // Should return an element that focus can be set to
    returnFocusToFunc: PropTypes.func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      ...props.store.getState(),
      endUserTutorialShown: false,
    }
  }

  componentDidMount() {
    this.props.store.addChangeListener(this.handleStoreChange)
  }

  componentWillUnmount() {
    this.props.store.removeChangeListener(this.handleStoreChange)
  }

  handleStoreChange = () => {
    this.setState(this.props.store.getState())
  }

  handleToggleClick = () => {
    this.props.store.setState({
      isCollapsed: !this.state.isCollapsed,
    })
  }

  handleEndTutorialClick = () => {
    this.setState({
      endUserTutorialShown: true,
    })
  }

  closeEndTutorialDialog = () => {
    this.setState({
      endUserTutorialShown: false,
    })
    if (this.endTutorialButton) {
      this.endTutorialButton.focus()
    }
  }

  handleEntering = () => {
    this.toggleButton.focus()
  }

  handleExiting = () => {
    this.props.returnFocusToFunc().focus()
  }

  render() {
    return (
      <Tray
        label={this.props.label}
        open={!this.state.isCollapsed}
        placement="end"
        zIndex="100"
        onExiting={this.handleExiting}
        onEntered={this.handleEntering}
        shouldContainFocus={true}
        size="regular"
      >
        <View as="div" className="NewUserTutorialTray" padding="medium none none">
          <View position="absolute" insetInlineEnd="1rem" insetBlockStart="1rem" insetBlockEnd="0">
            <NewUserTutorialToggleButton
              ref={c => {
                this.toggleButton = c
              }}
              onClick={this.handleToggleClick}
              store={this.props.store}
            />
          </View>
          <View display="block" padding="none large">
            {this.props.children}
          </View>
          <View
            display="block"
            textAlign="end"
            background="secondary"
            padding="small medium"
            borderWidth="small none none"
          >
            <Button
              onClick={this.handleEndTutorialClick}
              ref={c => {
                this.endTutorialButton = c
              }}
            >
              {I18n.t(`Don't Show Again`)}
            </Button>
          </View>
          <ConfirmEndTutorialDialog
            isOpen={this.state.endUserTutorialShown}
            handleRequestClose={this.closeEndTutorialDialog}
          />
        </View>
      </Tray>
    )
  }
}

export default TutorialTray
