/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {number} from 'prop-types'
import React from 'react'
import '@canvas/content-locks/jquery/lock_reason'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

PeerReviewsCounter.propTypes = {
  current: number,
  total: number,
}

export default function PeerReviewsCounter(props) {
  return (
    <>
      <Text as="span" size="x-large">
        {I18n.t('Review ')}
      </Text>
      <Text as="span" color="primary" size="x-large" weight="bold" data-testid="current-counter">
        {props.current}
      </Text>
      &nbsp;
      <Text as="span" size="x-large" data-testid="total-counter">
        {I18n.t('of %{total}', {total: props.total})}
      </Text>
    </>
  )
}
