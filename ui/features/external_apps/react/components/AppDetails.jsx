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

import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import page from 'page'
import Header from './Header'
import AddApp from './AddApp'
import '@canvas/rails-flash-notifications'

const I18n = createI18nScope('external_tools')

export default class AppDetails extends React.Component {
  static propTypes = {
    store: PropTypes.object.isRequired,
    baseUrl: PropTypes.string.isRequired,
    shortName: PropTypes.string.isRequired,
  }

  constructor(props) {
    super(props)
    this.addAppButtonRef = React.createRef()
    this.appNameRef = React.createRef()
    this.appDescriptionRef = React.createRef()
  }

  state = {
    app: null,
  }

  componentDidMount() {
    const app = this.props.store.findAppByShortName(this.props.shortName)
    if (app) {
      this.setState({app})
    } else {
      page('/')
    }
  }

  handleToolInstalled = () => {
    const app = this.state.app
    app.is_installed = true
    this.setState({app})
    this.props.store.flagAppAsInstalled(app.short_name)
    this.props.store.setState({filter: 'installed', filterText: ''})
    $.flashMessage(I18n.t('The app was added successfully'))
    page('/')
  }

  alreadyInstalled = () => {
    if (this.state.app.is_installed) {
      return <div className="gray-box-centered">{I18n.t('Installed')}</div>
    }
  }

  render() {
    if (!this.state.app) {
      return <img src="/images/ajax-loader-linear.gif" alt={I18n.t('Loading')} />
    }

    return (
      <div className="AppDetails">
        <Header>
          <a
            href={`${this.props.baseUrl}/configurations`}
            className="btn view_tools_link lm pull-right"
          >
            {I18n.t('View App Configurations')}
          </a>
          <a href={this.props.baseUrl} className="btn view_tools_link lm pull-right">
            {I18n.t('View App Center')}
          </a>
        </Header>
        <div className="app_full">
          <table className="individual-app">
            <tbody>
              <tr>
                <td className="individual-app-left" valign="top">
                  <div className="app">
                    <img
                      aria-hidden={true}
                      alt=""
                      className="img-polaroid"
                      src={this.state.app.banner_image_url}
                    />
                    {this.alreadyInstalled()}
                  </div>
                  <AddApp
                    ref={this.addAppButtonRef}
                    app={this.state.app}
                    handleToolInstalled={this.handleToolInstalled}
                  />

                  <a href={this.props.baseUrl} className="app_cancel">
                    &laquo; {I18n.t('Back to App Center')}
                  </a>
                </td>
                <td className="individual-app-right" valign="top">
                  <h2 ref={this.appNameRef}>{this.state.app.name}</h2>
                  <p
                    ref={this.appDescriptionRef}
                    dangerouslySetInnerHTML={{__html: this.state.app.description}}
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    )
  }
}
