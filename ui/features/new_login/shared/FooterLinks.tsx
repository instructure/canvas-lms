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
import {View, ViewOwnProps} from '@instructure/ui-view'
import React from 'react'
import {useHelpTray, useNewLogin, useNewLoginData} from '../context'

const I18n = createI18nScope('new_login')

const FooterLinks = () => {
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode, helpLink} = useNewLoginData()
  const {openHelpTray} = useHelpTray()

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
    <View as="div" textAlign="center">
      <InlineList delimiter="pipe" size="small">
        {helpLink && (
          <InlineList.Item>
            <Link
              href="https://community.canvaslms.com/"
              target="_blank"
              onClick={event => handleClick(event as React.MouseEvent<ViewOwnProps>, true)}
              data-track-category={helpLink.trackCategory}
              data-track-label={helpLink.trackLabel}
              data-testid="help-link"
            >
              {helpLink.text}
            </Link>
          </InlineList.Item>
        )}

        <InlineList.Item>
          <Link href="/privacy_policy" onClick={handleClick} data-testid="privacy-link">
            {I18n.t('Privacy Policy')}
          </Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link
            href="https://www.instructure.com/policies/canvas-lms-cookie-notice"
            target="_blank"
            onClick={handleClick}
            data-testid="cookie-notice-link"
          >
            {I18n.t('Cookie Notice')}
          </Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link href="/acceptable_use_policy" onClick={handleClick} data-testid="aup-link">
            {I18n.t('Acceptable Use Policy')}
          </Link>
        </InlineList.Item>
      </InlineList>
    </View>
  )
}

export default FooterLinks
