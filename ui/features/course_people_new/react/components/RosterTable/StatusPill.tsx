/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Pill} from '@instructure/ui-pill'
import {PENDING_ENROLLMENT, INACTIVE_ENROLLMENT} from '../../../util/constants'
import type {EnrollmentState} from '../../../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

type PillColor = "primary" | "info" | "alert" | "success" | "danger" | "warning" | undefined

const StatusPill = ({state}: {state: EnrollmentState}) => {
  const renderPill = (text: string, color: PillColor) => <Pill color={color}>{text}</Pill>

  if (state === PENDING_ENROLLMENT) return renderPill(I18n.t('Pending'), 'info')
  if (state === INACTIVE_ENROLLMENT) return renderPill(I18n.t('Inactive'), 'primary')

  return null
}

export default StatusPill
