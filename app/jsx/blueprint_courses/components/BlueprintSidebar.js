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

import Tray from 'instructure-ui/lib/components/Tray'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import Heading from 'instructure-ui/lib/components/Heading'
import IconCopyLine from 'instructure-icons/lib/Line/IconCopyLine'
import IconXSolid from 'instructure-icons/lib/Solid/IconXSolid'

export default class BlueprintCourseSidebar extends Component {
  static propTypes = {
    onOpen: PropTypes.func,
    children: PropTypes.node,
  }

  static defaultProps = {
    children: null,
    onOpen: () => {},
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
          <Button ref={(c) => { this.openBtn = c }} variant="icon" onClick={this.open}>
            <Typography color="primary-inverse" size="large">
              <IconCopyLine title={I18n.t('Open sidebar')} />
            </Typography>
          </Button>
        </div>
        <Tray
          label={I18n.t('Blueprint Settings')}
          isDismissable={false}
          trapFocus
          isOpen={this.state.isOpen}
          placement="end"
          onEntering={this.handleOpen}
          onExiting={this.handleClose}
        >
          <div className="bcs__content">
            <header className="bcs__header">
              <Heading color="primary-inverse" level="h3">
                <div className="bcs__close-wrapper">
                  <Button variant="icon" onClick={this.close} ref={(c) => { this.closeBtn = c }}>
                    <Typography color="primary-inverse" size="small">
                      <IconXSolid title={I18n.t('Close sidebar')} />
                    </Typography>
                  </Button>
                </div>
                <IconCopyLine />&nbsp;{I18n.t('Blueprint')}
              </Heading>
            </header>
            <div className="bcs__body">
              {this.props.children}
            </div>
          </div>
        </Tray>
      </div>
    )
  }
}
