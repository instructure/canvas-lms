/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Link} from '@instructure/ui-link'
import {InlineList} from '@instructure/ui-list'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import type React from 'react'
import {useHelpTray, useNewLogin, useNewLoginData} from '../context'

const I18n = createI18nScope('new_login')

const FooterLinks = () => {
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode, helpLink, requireAup} = useNewLoginData()
  const {openHelpTray, isHelpTrayOpen} = useHelpTray()

  const isDisabled = isPreviewMode || isUiActionPending

  const handleClick = (event: React.MouseEvent<ViewOwnProps>, shouldOpenHelpTray = false) => {
    if (isDisabled) {
      event.preventDefault()
    } else if (shouldOpenHelpTray) {
      event.preventDefault()
      openHelpTray()
    }
  }

  return (
    <View as="div" textAlign="center" data-testid="footer-links">
      <InlineList delimiter="pipe" size="small">
        {helpLink && (
          <InlineList.Item>
            <Link
              aria-controls="helpTray"
              aria-expanded={isHelpTrayOpen}
              as="button"
              data-testid="help-link"
              data-track-category={helpLink.trackCategory}
              data-track-label={helpLink.trackLabel}
              onClick={event => handleClick(event as React.MouseEvent<ViewOwnProps>, true)}
            >
              {helpLink.text}
            </Link>
          </InlineList.Item>
        )}

        <InlineList.Item>
          <Link
            data-testid="privacy-link"
            forceButtonRole={false}
            onClick={handleClick}
            href="/privacy_policy"
          >
            {I18n.t('Privacy Policy')}
          </Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link
            data-testid="cookie-notice-link"
            forceButtonRole={false}
            href="https://www.instructure.com/policies/canvas-lms-cookie-notice"
            onClick={handleClick}
          >
            {I18n.t('Cookie Notice')}
          </Link>
        </InlineList.Item>

        {requireAup && (
          <InlineList.Item>
            <Link
              data-testid="aup-link"
              forceButtonRole={false}
              href="/acceptable_use_policy"
              onClick={handleClick}
            >
              {I18n.t('Acceptable Use Policy')}
            </Link>
          </InlineList.Item>
        )}
      </InlineList>
    </View>
  )
}

export default FooterLinks
