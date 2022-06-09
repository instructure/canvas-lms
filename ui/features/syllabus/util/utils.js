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
import {initializeReaderButton} from '@canvas/immersive-reader/ImmersiveReader'

const I18n = useI18nScope('syllabus')

export function attachImmersiveReaderButton(mountPoints) {
  const title = I18n.t('Course Syllabus')
  const content = () => document.querySelector('#course_syllabus').innerHTML
  mountPoints.forEach(node => {
    initializeReaderButton(node, {content, title})
  })
}
