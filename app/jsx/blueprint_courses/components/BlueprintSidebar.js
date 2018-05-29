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

import I18n from 'i18n!blueprint_settings'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

import Tray from '@instructure/ui-overlays/lib/components/Tray'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Text from '@instructure/ui-elements/lib/components/Text'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import IconBlueprint from '@instructure/ui-icons/lib/Solid/IconBlueprint'
import IconXSolid from '@instructure/ui-icons/lib/Solid/IconX'

export default class BlueprintCourseSidebar extends Component {
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
    contentRef: null
  }

  constructor (props) {
    super(props)
    this.state = {
      isOpen: false,
    }
  }

  handleOpen = () => {
    this.props.onOpen()
    this.closeBtn.focus()
  }

  handleClose = () => {
    this.openBtn.focus()
    this.props.onClose()
  }

  open = () => {
    this.setState({ isOpen: true })
  }

  close = () => {
    this.setState({ isOpen: false })
  }

  render () {
    return (
      <div className="bcs__wrapper">
        <div className="bcs__trigger">
          <Button buttonRef={(c) => { this.openBtn = c }} variant="icon-inverse" onClick={this.open}>
            <Text color="primary-inverse" size="large">
              <IconBlueprint title={I18n.t('Open sidebar')} />
            </Text>
          </Button>
        </div>
        <Tray
          label={I18n.t('Blueprint Settings')}
          shouldContainFocus
          open={this.state.isOpen}
          placement="end"
          onEntered={this.handleOpen}
          onExiting={this.handleClose}
          contentRef={this.props.contentRef}
        >
          <div className="bcs__content">
            <header className="bcs__header">
              <div className="bcs__close-wrapper">
                <Button variant="icon-inverse" onClick={this.close} buttonRef={(c) => { this.closeBtn = c }}>
                  <Text color="primary-inverse" size="small">
                    <IconXSolid title={I18n.t('Close sidebar')} />
                  </Text>
                </Button>
              </div>
              <Heading color="primary-inverse" level="h3">
                <IconBlueprint /><span style={{marginLeft: '10px'}}>{I18n.t('Blueprint')}</span>
              </Heading>
            </header>
            <div className="bcs__body">
              {this.props.children}
            </div>
          </div>
        </Tray>
        {this.props.detachedChildren}
      </div>
    );
  }
}
