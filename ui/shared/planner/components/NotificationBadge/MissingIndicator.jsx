/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {string} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import Indicator from './Indicator'

const I18n = createI18nScope('planner')

export default function MissingIndicator(props) {
  const badgeMessage = I18n.t('Missing items for %{title}', {title: props.title})
  return (
    <Indicator
      title={badgeMessage}
      variant="invisible"
      testId={props.testId || 'missing-indicator'}
    />
  )
}

MissingIndicator.propTypes = {
  title: string.isRequired,
  testId: string,
}
