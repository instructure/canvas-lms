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
import {IconButton} from '@instructure/ui-buttons'
import {IconMoveStartLine, IconMoveEndLine} from '@instructure/ui-icons'
import plainStoreShape from '@canvas/util/react/proptypes/plainStoreShape'

const I18n = useI18nScope('new_user_tutorial')

class NewUserTutorialToggleButton extends React.Component {
  static propTypes = {
    store: PropTypes.shape(plainStoreShape).isRequired,
  }

  constructor(props) {
    super(props)
    this.state = props.store.getState()
  }

  componentDidMount() {
    this.props.store.addChangeListener(this.handleStoreChange)
  }

  componentWillUnmount() {
    this.props.store.removeChangeListener(this.handleStoreChange)
  }

  focus() {
    this.button.focus()
  }

  handleStoreChange = () => {
    this.setState(this.props.store.getState())
  }

  handleButtonClick = event => {
    event.preventDefault()

    this.props.store.setState({
      isCollapsed: !this.state.isCollapsed,
    })
  }

  render() {
    const isCollapsed = this.state.isCollapsed

    return (
      <IconButton
        ref={c => {
          this.button = c
        }}
        variant="icon"
        id="new_user_tutorial_toggle"
        onClick={this.handleButtonClick}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={
          isCollapsed ? I18n.t('Expand tutorial tray') : I18n.t('Collapse tutorial tray')
        }
      >
        {isCollapsed ? <IconMoveStartLine /> : <IconMoveEndLine />}
      </IconButton>
    )
  }
}

export default NewUserTutorialToggleButton
