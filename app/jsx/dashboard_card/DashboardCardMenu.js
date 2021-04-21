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
import I18n from 'i18n!dashcards'
import {Popover} from '@instructure/ui-popover'
import {Tabs} from '@instructure/ui-tabs'
import {CloseButton} from '@instructure/ui-buttons'

import ColorPicker from '../shared/ColorPicker'
import DashboardCardMovementMenu from './DashboardCardMovementMenu'

export default class DashboardCardMenu extends React.Component {
  static propTypes = {
    afterUpdateColor: PropTypes.func.isRequired,
    currentColor: PropTypes.string.isRequired,
    nicknameInfo: PropTypes.shape({
      nickname: PropTypes.string,
      originalName: PropTypes.string,
      courseId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      onNicknameChange: PropTypes.func
    }).isRequired,
    trigger: PropTypes.node.isRequired,
    assetString: PropTypes.string.isRequired,
    popoverContentRef: PropTypes.func,
    handleShow: PropTypes.func,
    handleMove: PropTypes.func,
    isFavorited: PropTypes.bool,
    currentPosition: PropTypes.number,
    lastPosition: PropTypes.number,
    onUnfavorite: PropTypes.func,
    menuOptions: PropTypes.shape({
      canMoveLeft: PropTypes.bool,
      canMoveRight: PropTypes.bool,
      canMoveToBeginning: PropTypes.bool,
      canMoveToEnd: PropTypes.bool
    })
  }

  static defaultProps = {
    popoverContentRef: () => {},
    handleShow: () => {},
    handleMove: () => {},
    currentPosition: 0,
    lastPosition: 0,
    menuOptions: null
  }

  constructor(props) {
    super(props)

    this.state = {
      show: false,
      selectedIndex: 0
    }
  }

  shouldComponentUpdate(nextProps, nextState) {
    // Don't rerender the popover every time the color changes
    // only when we open and close (flashes on each color select otherwise)
    return this.state !== nextState
  }

  handleMenuToggle = show => {
    this.setState({show})
  }

  handleClose = () => {
    this.setState({show: false})
  }

  handleMovementMenuSelect = () => {
    this.setState({show: false})
  }

  handleTabChange = (event, {index}) => {
    this.setState({
      selectedIndex: index
    })
  }

  render() {
    const {
      afterUpdateColor,
      currentColor,
      nicknameInfo,
      handleMove,
      handleShow,
      popoverContentRef,
      currentPosition,
      lastPosition,
      assetString,
      menuOptions,
      trigger
    } = this.props

    const colorPicker = (
      <div className="DashboardCardMenu__ColorPicker">
        <ColorPicker
          ref={c => (this._colorPicker = c)}
          assetString={assetString}
          afterUpdateColor={afterUpdateColor}
          hidePrompt
          nonModal
          hideOnScroll={false}
          withAnimation={false}
          withBorder={false}
          withBoxShadow={false}
          withArrow={false}
          currentColor={currentColor}
          nicknameInfo={nicknameInfo}
          afterClose={this.handleClose}
          parentComponent="DashboardCardMenu"
          focusOnMount={false}
        />
      </div>
    )

    const movementMenu = (
      <DashboardCardMovementMenu
        ref={c => (this._movementMenu = c)}
        cardTitle={nicknameInfo.nickname}
        currentPosition={currentPosition}
        lastPosition={lastPosition}
        assetString={assetString}
        menuOptions={menuOptions}
        handleMove={handleMove}
        isFavorited={this.props.isFavorited}
        onMenuSelect={this.handleMovementMenuSelect}
        onUnfavorite={this.props.onUnfavorite}
      />
    )

    const menuStyles = {
      width: 190,
      height: 310,
      paddingTop: 0
    }

    const selectedIndex = this.state.selectedIndex

    return (
      <Popover
        on="click"
        show={this.state.show}
        onToggle={this.handleMenuToggle}
        shouldContainFocus
        shouldReturnFocus
        defaultFocusElement={() => this._colorTab}
        onShow={handleShow}
        contentRef={popoverContentRef}
      >
        <Popover.Trigger>{trigger}</Popover.Trigger>
        <Popover.Content>
          <CloseButton
            buttonRef={c => (this._closeButton = c)}
            placement="end"
            onClick={() => this.setState({show: false})}
          >
            {I18n.t('Close')}
          </CloseButton>
          <div style={menuStyles}>
            <div>
              <Tabs
                ref={c => (this._tabList = c)}
                padding="none"
                variant="secondary"
                onRequestTabChange={this.handleTabChange}
              >
                <Tabs.Panel
                  padding="none"
                  renderTitle={I18n.t('Color')}
                  isSelected={selectedIndex === 0}
                  tabRef={c => (this._colorTab = c)}
                >
                  {colorPicker}
                </Tabs.Panel>
                <Tabs.Panel
                  padding="none"
                  renderTitle={I18n.t('Move')}
                  isSelected={selectedIndex === 1}
                >
                  {movementMenu}
                </Tabs.Panel>
              </Tabs>
            </div>
          </div>
        </Popover.Content>
      </Popover>
    )
  }
}
