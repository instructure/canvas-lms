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

import I18n from 'i18n!theme_editor'
import React from 'react'
import SVGWrapper from 'jsx/shared/SVGWrapper'
import ReactCSSTransitionGroup from 'react-addons-css-transition-group'

export default React.createClass({
    displayName: 'ThemeCard',

    propTypes: {
      name: React.PropTypes.string.isRequired,
      isActiveBrandConfig: React.PropTypes.bool.isRequired,
      isDeletable: React.PropTypes.bool.isRequired,
      isBeingDeleted: React.PropTypes.bool.isRequired,
      startDeleting: React.PropTypes.func.isRequired,
      cancelDeleting: React.PropTypes.func.isRequired,
      onDelete: React.PropTypes.func.isRequired,
      getVariable: React.PropTypes.func.isRequired
    },

    render () {
      const getVar = this.props.getVariable
      return (
        <div className={`ic-ThemeCard ${this.props.isActiveBrandConfig && 'ic-ThemeCard--is-active-theme'}`}>
          <div
            className="ic-ThemeCard-thumbnail"
            aria-hidden="true"
            onClick={this.props.open}
          >
            <div className="ic-ThemeCard-thumbnail__primary-content">
              <div className="ic-ThemeCard-fake-text"></div>
              <div
                className="ic-ThemeCard-fake-progressbar"
                style={{borderColor: getVar('ic-brand-primary')}}
              >
                <div
                  className="ic-ThemeCard-fake-progressbar__inner"
                  style={{ backgroundColor: getVar('ic-brand-primary') }}
                />
              </div>
              <div className="ic-ThemeCard-fake-radio">
                <div
                  className="ic-ThemeCard-fake-radio__inner"
                  style={{
                    backgroundColor: getVar('ic-brand-primary'),
                    borderColor: getVar('ic-brand-primary')
                  }}
                />
              </div>
              <div className="ic-ThemeCard-fake-checkbox">
                <div
                  className="ic-ThemeCard-fake-checkbox__inner"
                  style={{ backgroundColor: getVar('ic-brand-primary') }}
                >
                  <i className="icon-check"></i>
                </div>
              </div>
            </div>
            <div className="ic-ThemeCard-thumbnail__secondary-content">
              <div
                className="ic-ThemeCard-fake-button"
                style={{ backgroundColor: getVar('ic-brand-button--primary-bgd') }}
              />
              <div
                className="ic-ThemeCard-fake-button"
                style={{ backgroundColor: getVar('ic-brand-button--secondary-bgd') }}
              />
            </div>
            <div
              className="ic-ThemeCard-thumbnail__nav"
              style={{ backgroundColor: getVar('ic-brand-global-nav-bgd') }}
            >
              <div className="ic-ThemeCard-thumbnail__icon">
                <SVGWrapper
                  url="/images/svg-icons/svg_icon_courses_new_styles.svg"
                  fillColor={ getVar('ic-brand-global-nav-ic-icon-svg-fill') }
                />
                <div
                  className="ic-ThemeCard-thumbnail__icon-text"
                  style={{ backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color') }}
                />
              </div>
              <div className="ic-ThemeCard-thumbnail__icon">
                <SVGWrapper
                  url="/images/svg-icons/svg_icon_calendar_new_styles.svg"
                  fillColor={ getVar('ic-brand-global-nav-ic-icon-svg-fill') }
                />
                <div
                  className="ic-ThemeCard-thumbnail__icon-text"
                  style={{ backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color') }}
                />
              </div>
              <div className="ic-ThemeCard-thumbnail__icon">
                <SVGWrapper
                  url="/images/svg-icons/svg_icon_inbox.svg"
                  fillColor={ getVar('ic-brand-global-nav-ic-icon-svg-fill') }
                />
                <div
                  className="ic-ThemeCard-thumbnail__icon-text"
                  style={{ backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color') }}
                />
              </div>
            </div>
            { !this.props.isBeingDeleted && <div className="ic-ThemeCard-overlay">
                <div className="ic-ThemeCard-overlay__content">
                  <div className="Button Button--primary">
                    {I18n.t('Open in Theme Editor')}
                  </div>
                </div>
              </div>
            }
          </div>
          <div className="ic-ThemeCard-main">
            <div className="ic-ThemeCard-main__name">
              <button
                type="button"
                className="ic-ThemeCard-name-button"
                onClick={this.props.open}
              >
                <span className="screenreader-only">
                  { this.props.isActiveBrandConfig ? I18n.t('This is your current theme') : null }
                  {I18n.t('Edit this theme in Theme Editor')}
                </span>
                {this.props.name}
              </button>
            </div>
            <div className="ic-ThemeCard-main__actions">
              { this.props.isDeletable &&
                <button className="Button Button--icon-action" onClick={this.props.startDeleting}>
                  <span className="screenreader-only">{I18n.t('Delete theme')}</span>
                  <i className="icon-trash" />
                </button>
              }
            </div>
          </div>
          <ReactCSSTransitionGroup transitionName="ic-ThemeCard-overlay-transition">
          { this.props.isBeingDeleted &&
            <div className="ic-ThemeCard-overlay">
              <div className="ic-ThemeCard-overlay__content">
                <h4 className="ic-ThemeCard-overlay__heading">
                  {I18n.t('Delete this theme?')}
                </h4>
                <div className="ic-ThemeCard-overlay__actions">
                  <button
                    type="button"
                    className="Button"
                    onClick={this.props.cancelDeleting}
                  >
                    {I18n.t('Cancel')}
                  </button>
                  <button
                    type="button"
                    className="Button Button--danger"
                    onClick={this.props.onDelete}
                  >
                    {I18n.t('Delete')}
                  </button>
                </div>
              </div>
            </div>
          }
          </ReactCSSTransitionGroup>
          { this.props.isActiveBrandConfig &&
            <div
              className="ic-ThemeCard-status ic-ThemeCard-status--is-active-theme"
              aria-hidden="true"
            >
              <i className="icon-check ic-ThemeCard-status__icon" />
              &nbsp;&nbsp;
              <span className="ic-ThemeCard-status__text">
                {I18n.t('Current theme')}
              </span>
            </div>
          }
        </div>
      )
    }
  })
