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

import React from 'react'
import classNames from 'classnames'
import {InlineList} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

const FooterLinks = ({className}: Props) => {
  return (
    <View as="div" className={classNames(className)} textAlign="center">
      <InlineList delimiter="pipe" size="small">
        <InlineList.Item>
          <Link href="https://community.canvaslms.com/" target="_blank">
            Help
          </Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link href="/privacy_policy">{I18n.t('Privacy Policy')}</Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link
            href="https://www.instructure.com/policies/canvas-lms-cookie-notice"
            target="_blank"
          >
            {I18n.t('Cookie Notice')}
          </Link>
        </InlineList.Item>

        <InlineList.Item>
          <Link href="#">{I18n.t('Acceptable Use Policy')}</Link>
        </InlineList.Item>
      </InlineList>
    </View>
  )
}

export default FooterLinks
