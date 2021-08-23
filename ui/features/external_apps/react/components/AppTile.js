/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!external_tools'
import $ from 'jquery'
import React from 'react'
import page from 'page'

export default class extends React.Component {
  static displayName = 'AppTile'

  state = {
    isHidingDetails: true
  }

  showDetails = () => {
    if (this.state.isHidingDetails) {
      $(this.details).fadeTo(200, 0.85)
      this.setState({isHidingDetails: false})
    }
  }

  hideDetails = () => {
    $(this.details).fadeOut(200, () => {
      try {
        this.setState({isHidingDetails: true})
      } catch (error) {
        // component was unmounted
      }
    })
  }

  handleKeyDown = e => {
    if (e.which == 13) {
      this.handleClick(e)
    }
  }

  handleClick = e => {
    e.preventDefault()
    page(`${this.props.pathname}/app/${this.props.app.short_name}`)
  }

  installedRibbon = () => {
    if (this.props.app.is_installed) {
      return <div className="installed-ribbon">{I18n.t('Installed')}</div>
    }
  }

  render() {
    const appId = `app_${this.props.app.id}`

    return (
      <a
        role="button"
        tabIndex="0"
        aria-label={I18n.t('View %{name} app', {name: this.props.app.name})}
        aria-describedby={`${appId}-desc`}
        className="app"
        onMouseEnter={this.showDetails}
        onMouseLeave={this.hideDetails}
        onClick={this.handleClick}
        onKeyDown={this.handleKeyDown}
      >
        <div id={appId}>
          {this.installedRibbon()}

          <img
            className="banner_image"
            alt={this.props.app.name}
            src={this.props.app.banner_image_url}
          />
          <div
            ref={c => {
              this.details = c
            }}
            className="details"
          >
            <div className="content">
              <span className="name">{this.props.app.name}</span>
              <div id={`${appId}-desc`} className="desc">
                {this.props.app.short_description}
              </div>
            </div>
          </div>
        </div>
      </a>
    )
  }
}
