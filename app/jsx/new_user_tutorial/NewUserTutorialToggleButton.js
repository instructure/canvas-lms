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
import I18n from 'i18n!new_user_tutorial'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconMoveStart from '@instructure/ui-icons/lib/Line/IconMoveStart'
import IconMoveEnd from '@instructure/ui-icons/lib/Line/IconMoveEnd'
import plainStoreShape from '../shared/proptypes/plainStoreShape'

  class NewUserTutorialToggleButton extends React.Component {

    static propTypes = {
      store: PropTypes.shape(plainStoreShape).isRequired
    }

    constructor (props) {
      super(props);
      this.state = props.store.getState();
    }

    componentDidMount () {
      this.props.store.addChangeListener(this.handleStoreChange)
    }

    componentWillUnmount () {
      this.props.store.removeChangeListener(this.handleStoreChange)
    }

    focus () {
      this.button.focus();
    }

    handleStoreChange = () => {
      this.setState(this.props.store.getState());
    }

    handleButtonClick = (event) => {
      event.preventDefault();

      this.props.store.setState({
        isCollapsed: !this.state.isCollapsed
      });
    }

    render () {
      return (
        <Button
          ref={(c) => { this.button = c; }}
          variant="icon"
          id="new_user_tutorial_toggle"
          onClick={this.handleButtonClick}
        >
          {
            (this.state.isCollapsed) ?
            (<IconMoveStart title={I18n.t('Expand tutorial tray')} />) :
            (<IconMoveEnd title={I18n.t('Collapse tutorial tray')} />)
          }
        </Button>
      );
    }
  }

export default NewUserTutorialToggleButton;

