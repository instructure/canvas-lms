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
import {useScope as useI18nScope} from '@canvas/i18n'

import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {
  IconMoveUpTopLine,
  IconMoveUpLine,
  IconMoveDownLine,
  IconMoveDownBottomLine,
  IconStarSolid,
} from '@instructure/ui-icons'

const I18n = useI18nScope('dashcards')

type Props = {
  assetString: string
  handleMove: (assetString: string, positionToMoveTo: number) => void
  isFavorited: boolean
  onMenuSelect: () => void
  onUnfavorite: () => void
  menuOptions: {
    canMoveLeft: boolean
    canMoveRight: boolean
    canMoveToBeginning: boolean
    canMoveToEnd: boolean
  }
  lastPosition: number
  currentPosition: number
}

class DashboardCardMovementMenu extends React.Component<Props> {
  static defaultProps = {
    onMenuSelect: () => {},
    lastPosition: 0,
    currentPosition: 0,
  }

  handleMoveCard = (positionToMoveTo: number) => () =>
    this.props.handleMove(this.props.assetString, positionToMoveTo)

  render() {
    const {canMoveLeft, canMoveRight, canMoveToBeginning, canMoveToEnd} = this.props.menuOptions

    return (
      <Menu label={I18n.t('Dashboard Card Movement Menu')} onSelect={this.props.onMenuSelect}>
        {!!canMoveToBeginning && (
          <Menu.Item onSelect={this.handleMoveCard(0)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveUpTopLine className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Move to top')}
              </Text>
            </span>
          </Menu.Item>
        )}
        {!!canMoveLeft && (
          <Menu.Item onSelect={this.handleMoveCard(this.props.currentPosition - 1)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveUpLine className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Move up')}
              </Text>
            </span>
          </Menu.Item>
        )}
        {!!canMoveRight && (
          <Menu.Item onSelect={this.handleMoveCard(this.props.currentPosition + 1)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveDownLine className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Move down')}
              </Text>
            </span>
          </Menu.Item>
        )}
        {!!canMoveToEnd && (
          <Menu.Item onSelect={this.handleMoveCard(this.props.lastPosition)}>
            <span className="DashboardCardMenu__MovementItem">
              <IconMoveDownBottomLine className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Move to bottom')}
              </Text>
            </span>
          </Menu.Item>
        )}
        {!!this.props.isFavorited && (
          <Menu.Item id="unfavorite" onClick={this.props.onUnfavorite}>
            <span className="DashboardCardMenu__MovementItem">
              <IconStarSolid className="DashboardCardMenu__MovementIcon" />
              <Text weight="bold" size="small">
                {I18n.t('Unfavorite')}
              </Text>
            </span>
          </Menu.Item>
        )}
      </Menu>
    )
  }
}

export default DashboardCardMovementMenu
