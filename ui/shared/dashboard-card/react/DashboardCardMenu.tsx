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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Popover} from '@instructure/ui-popover'
import {Tabs} from '@instructure/ui-tabs'
import {CloseButton} from '@instructure/ui-buttons'

import ColorPicker from '@canvas/color-picker'
import DashboardCardMovementMenu from './DashboardCardMovementMenu'

const I18n = useI18nScope('dashcards')

type Props = {
  afterUpdateColor: any
  currentColor: string
  nicknameInfo: {
    nickname: string
    originalName: string
    courseId: string | number
    onNicknameChange: any
  }
  trigger: any
  assetString: string
  popoverContentRef: any
  handleShow: any
  handleMove: any
  isFavorited: boolean
  currentPosition: number
  lastPosition: number
  onUnfavorite: any
  menuOptions: {
    canMoveLeft: boolean
    canMoveRight: boolean
    canMoveToBeginning: boolean
    canMoveToEnd: boolean
  }
}

type State = {
  show: boolean
  selectedIndex: number
}

export default class DashboardCardMenu extends React.Component<Props, State> {
  _colorPicker: any

  _closeButton: any

  _colorTab: any

  _movementMenu: any

  _tabList: any

  static defaultProps = {
    popoverContentRef: () => {},
    handleShow: () => {},
    handleMove: () => {},
    currentPosition: 0,
    lastPosition: 0,
    menuOptions: null,
  }

  constructor(props: Props) {
    super(props)

    this.state = {
      show: false,
      selectedIndex: 0,
    }
  }

  shouldComponentUpdate(nextProps: Props, nextState: State) {
    // Don't rerender the popover every time the color changes
    // only when we open and close (flashes on each color select otherwise)
    return this.state !== nextState
  }

  handleMenuOpen = () => {
    this.setState({show: true})
  }

  handleMenuClose = () => {
    this.setState({show: false})
  }

  handleMovementMenuSelect = () => {
    this.setState({show: false})
  }

  handleTabChange = (
    event: unknown,
    {
      index,
    }: {
      index: number
    }
  ) => {
    this.setState({
      selectedIndex: index,
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
      trigger,
    } = this.props

    const colorPicker = (
      <div className="DashboardCardMenu__ColorPicker">
        <ColorPicker
          ref={(c: unknown) => (this._colorPicker = c)}
          assetString={assetString}
          afterUpdateColor={afterUpdateColor}
          hidePrompt={true}
          nonModal={true}
          hideOnScroll={false}
          withAnimation={false}
          withBorder={false}
          withBoxShadow={false}
          withArrow={false}
          currentColor={currentColor}
          nicknameInfo={nicknameInfo}
          afterClose={this.handleMenuClose}
          parentComponent="DashboardCardMenu"
          focusOnMount={false}
        />
      </div>
    )

    const movementMenu = (
      <DashboardCardMovementMenu
        ref={(c: unknown) => (this._movementMenu = c)}
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
      paddingTop: 0,
    }

    const selectedIndex = this.state.selectedIndex

    return (
      <Popover
        on="click"
        isShowingContent={this.state.show}
        onShowContent={this.handleMenuOpen}
        onHideContent={this.handleMenuClose}
        shouldContainFocus={true}
        shouldReturnFocus={true}
        defaultFocusElement={() => this._colorTab}
        onPositioned={handleShow}
        contentRef={popoverContentRef}
        renderTrigger={trigger}
      >
        <CloseButton
          elementRef={c => (this._closeButton = c)}
          placement="end"
          onClick={() => this.setState({show: false})}
          screenReaderLabel={I18n.t('Close')}
        />
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
                // @ts-expect-error TODO: change to elementRef
                tabRef={(c: unknown) => (this._colorTab = c)}
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
      </Popover>
    )
  }
}
