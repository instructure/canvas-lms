/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import $ from 'jquery'
import {shape, func, object} from 'prop-types'
import {Tray} from '@instructure/ui-tray'
import preventDefault from 'prevent-default'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('MobileNavigation')

const MobileContextMenu = React.lazy(() => import('./MobileContextMenu'))
const MobileGlobalMenu = React.lazy(() => import('./MobileGlobalMenu'))

export default class MobileNavigation extends React.Component {
  state = {
    globalNavIsOpen: false,
    contextNavIsOpen: false,
  }

  static propTypes = {
    DesktopNavComponent: shape({
      ensureLoaded: func.isRequired,
      state: object.isRequired,
    }).isRequired,
  }

  componentDidMount() {
    $('.mobile-header-hamburger').on(
      'touchstart click',
      preventDefault(() => this.setState({globalNavIsOpen: true}))
    )

    const arrowIcon = document.getElementById('mobileHeaderArrowIcon')
    const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')
    $('.mobile-header-title.expandable, .mobile-header-arrow').on(
      'touchstart click',
      preventDefault(() => {
        this.setState(state => {
          const contextNavIsOpen = !state.contextNavIsOpen

          // gotta do some manual dom manip for the non-react arrow/close icon
          arrowIcon.className = contextNavIsOpen ? 'icon-x' : 'icon-arrow-open-down'
          mobileContextNavContainer.setAttribute('aria-expanded', contextNavIsOpen)

          return {contextNavIsOpen}
        })
      })
    )
  }

  render() {
    const closeGlobalNav = () => this.setState({globalNavIsOpen: false})
    const spinner = (
      <View display="block" textAlign="center">
        <Spinner size="large" margin="large auto" renderTitle={() => I18n.t('...Loading')} />
      </View>
    )
    return (
      <>
        {this.state.globalNavIsOpen && (
          <Tray
            size="large"
            label={I18n.t('Global Navigation')}
            open={this.state.globalNavIsOpen}
            onDismiss={closeGlobalNav}
            shouldCloseOnDocumentClick={true}
          >
            {this.state.globalNavIsOpen && (
              <React.Suspense fallback={spinner}>
                <MobileGlobalMenu
                  DesktopNavComponent={this.props.DesktopNavComponent}
                  onDismiss={closeGlobalNav}
                />
              </React.Suspense>
            )}
          </Tray>
        )}
        {this.state.contextNavIsOpen && (
          <React.Suspense fallback={spinner}>
            <MobileContextMenu spinner={spinner} />
          </React.Suspense>
        )}
      </>
    )
  }
}
