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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import PropTypes from 'prop-types'
import {Tray} from '@instructure/ui-tray'
import {IconButton, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {IconBlueprintSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('BlueprintCourseSidebar')

interface BlueprintSidebarProps {
  onOpen?: () => void
  onClose?: () => void
  children?: React.ReactNode
  detachedChildren?: React.ReactNode
  contentRef?: ((el: HTMLSpanElement | null) => void) | null
}

interface BlueprintSidebarState {
  isOpen: boolean
}

export default class BlueprintCourseSidebar extends Component<
  BlueprintSidebarProps,
  BlueprintSidebarState
> {
  static propTypes = {
    onOpen: PropTypes.func,
    onClose: PropTypes.func,
    children: PropTypes.node,
    detachedChildren: PropTypes.node,
    contentRef: PropTypes.func, // for unit testing
  }

  static defaultProps = {
    children: null,
    detachedChildren: null,
    onOpen: () => {},
    onClose: () => {},
    contentRef: null,
  }

  openBtn: {focus: () => void} | null = null
  closeBtn: {focus: () => void} | null = null

  constructor(props: BlueprintSidebarProps) {
    super(props)
    this.state = {
      isOpen: false,
    }
  }

  handleOpen = () => {
    this.props.onOpen?.()
    this.closeBtn?.focus()
  }

  handleClose = () => {
    this.openBtn?.focus()
    this.props.onClose?.()
  }

  open = () => {
    this.setState({isOpen: true})
  }

  close = () => {
    this.setState({isOpen: false})
  }

  componentDidMount() {
    const topNavigationButtons = document.getElementsByClassName('right-of-crumbs')[0]
    window.openBPSidebar = this.open
    if (topNavigationButtons) {
      topNavigationButtons.classList.add('bp-sync-button-exists')
    }
  }

  render() {
    return (
      <div className="bcs__wrapper">
        <div className="bcs__trigger">
          <IconButton
            renderIcon={IconBlueprintSolid}
            screenReaderLabel={I18n.t('Open Blueprint Sidebar')}
            onClick={this.open}
            elementRef={(c: Element | null) => {
              this.openBtn = c as unknown as {focus: () => void} | null
            }}
            color="primary-inverse"
            withBorder={false}
            withBackground={false}
          />
        </div>
        <Tray
          label={I18n.t('Blueprint Settings')}
          shouldContainFocus={true}
          open={this.state.isOpen}
          placement="end"
          onEntered={this.handleOpen}
          onExiting={this.handleClose}
          contentRef={this.props.contentRef ?? undefined}
        >
          <div className="bcs__content">
            <header className="bcs__header">
              <View as="div" padding="medium" textAlign="center">
                <CloseButton
                  screenReaderLabel={I18n.t('Close sidebar')}
                  onClick={this.close}
                  elementRef={(c: Element | null) => {
                    this.closeBtn = c as unknown as {focus: () => void} | null
                  }}
                  color="primary-inverse"
                  placement="start"
                  offset="medium"
                />
                <Heading color="primary-inverse" level="h3">
                  <IconBlueprintSolid />
                  <span style={{marginLeft: '10px'}}>{I18n.t('Blueprint')}</span>
                </Heading>
              </View>
            </header>
            <div className="bcs__body">{this.props.children}</div>
          </div>
        </Tray>
        {this.props.detachedChildren}
      </div>
    )
  }
}
