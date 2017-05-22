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
import I18n from 'i18n!dashcards'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import { MenuItem, MenuItemSeparator } from 'instructure-ui/lib/components/Menu'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import Button from 'instructure-ui/lib/components/Button'

  class DashboardCardMovementMenu extends React.Component {

    static propTypes = {
      cardTitle: React.PropTypes.string.isRequired,
      assetString: React.PropTypes.string.isRequired,
      handleMove: React.PropTypes.func.isRequired,
      menuOptions: React.PropTypes.shape({
        canMoveLeft: React.PropTypes.bool,
        canMoveRight: React.PropTypes.bool,
        canMoveToBeginning: React.PropTypes.bool,
        canMoveToEnd: React.PropTypes.bool
      }).isRequired,
      lastPosition: React.PropTypes.number,
      currentPosition: React.PropTypes.number
    };

    handleMoveCard = positionToMoveTo => () => this.props.handleMove(this.props.assetString, positionToMoveTo);

    render () {
      const menuLabel = (
        <div>
          <ScreenReaderContent>
            {I18n.t('Card Movement Menu for %{title}', { title: this.props.cardTitle })}
          </ScreenReaderContent>
          <i className="icon-more" />
        </div>
      );

      const popoverTrigger = (
        <Button
          variant="icon-inverse"
          size="small"
        >
          {menuLabel}
        </Button>
      );

      const {
        canMoveLeft,
        canMoveRight,
        canMoveToBeginning,
        canMoveToEnd
      } = this.props.menuOptions;

      return (
        <div className="DashboardCardMovementMenu">
          <PopoverMenu
            trigger={popoverTrigger}
          >
            {!!canMoveLeft && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.currentPosition - 1)}
              >
                {I18n.t('Move Left')}
              </MenuItem>
            )}
            {!!canMoveRight && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.currentPosition + 1)}
              >
                {I18n.t('Move Right')}
              </MenuItem>
            )}
            {(!!canMoveToBeginning || !!canMoveToEnd) && (
              <MenuItemSeparator />
            )}
            {!!canMoveToBeginning && (
              <MenuItem
                onSelect={this.handleMoveCard(0)}
              >
                {I18n.t('Move to the Beginning')}
              </MenuItem>
            )}
            {!!canMoveToEnd && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.lastPosition)}
              >
                {I18n.t('Move to the End')}
              </MenuItem>
            )}
          </PopoverMenu>
        </div>
      );
    }
  }

export default DashboardCardMovementMenu
