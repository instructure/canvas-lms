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
import PropTypes from 'prop-types'
import I18n from 'i18n!dashcards'
import Menu, {MenuItem} from '@instructure/ui-menu/lib/components/Menu'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconMoveUpTopSolid from '@instructure/ui-icons/lib/Solid/IconMoveUpTop'
import IconMoveUpSolid from '@instructure/ui-icons/lib/Solid/IconMoveUp'
import IconMoveDownSolid from '@instructure/ui-icons/lib/Solid/IconMoveDown'
import IconMoveDownBottomSolid from '@instructure/ui-icons/lib/Solid/IconMoveDownBottom'

class DashboardCardMovementMenu extends React.Component {
  static propTypes = {
    assetString: PropTypes.string.isRequired,
    handleMove: PropTypes.func.isRequired,
    onMenuSelect: PropTypes.func,
    menuOptions: PropTypes.shape({
      canMoveLeft: PropTypes.bool,
      canMoveRight: PropTypes.bool,
      canMoveToBeginning: PropTypes.bool,
      canMoveToEnd: PropTypes.bool
    }).isRequired,
    lastPosition: PropTypes.number,
    currentPosition: PropTypes.number
  }

  static defaultProps = {
    onMenuSelect: () => {},
    lastPosition: 0,
    currentPosition: 0
  }

  handleMoveCard = positionToMoveTo => () =>
    this.props.handleMove(this.props.assetString, positionToMoveTo)

  render() {
    const {canMoveLeft, canMoveRight, canMoveToBeginning, canMoveToEnd} = this.props.menuOptions

    return (
      <Menu onSelect={this.props.onMenuSelect}>
        {!!canMoveToBeginning && (
          <MenuItem onSelect={this.handleMoveCard(0)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveUpTopSolid className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Top')}
              </Text>
            </span>
          </MenuItem>
        )}
        {!!canMoveLeft && (
          <MenuItem onSelect={this.handleMoveCard(this.props.currentPosition - 1)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveUpSolid className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Ahead')}
              </Text>
            </span>
          </MenuItem>
        )}
        {!!canMoveRight && (
          <MenuItem onSelect={this.handleMoveCard(this.props.currentPosition + 1)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveDownSolid className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Behind')}
              </Text>
            </span>
          </MenuItem>
        )}
        {!!canMoveToEnd && (
          <MenuItem onSelect={this.handleMoveCard(this.props.lastPosition)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveDownBottomSolid className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Bottom')}
              </Text>
            </span>
          </MenuItem>
        )}
      </Menu>
    )
  }
}

export default DashboardCardMovementMenu
