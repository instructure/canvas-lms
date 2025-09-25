/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import {Pill} from '@instructure/ui-pill'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('gradingStatusPill')

// Store roots to prevent multiple createRoot calls on same element
const rootMap = new WeakMap()

function getOrCreateRoot(element) {
  if (rootMap.has(element)) {
    return rootMap.get(element)
  }
  const root = createRoot(element)
  rootMap.set(element, root)
  return root
}

function forEachNode(nodeList, fn) {
  for (let i = 0; i < nodeList.length; i += 1) {
    fn(nodeList[i])
  }
}

export default {
  renderPills(customStatuses = []) {
    const statusMap =
      customStatuses?.reduce((statusMap, status) => {
        statusMap[status.id] = status
        return statusMap
      }, {}) ?? {}

    const missMountPoints = document.querySelectorAll('.submission-missing-pill')
    const lateMountPoints = document.querySelectorAll('.submission-late-pill')
    const excusedMountPoints = document.querySelectorAll('.submission-excused-pill')
    const extendedMountPoints = document.querySelectorAll('.submission-extended-pill')
    const customGradeStatusMountPoints = document.querySelectorAll(
      '[class^="submission-custom-grade-status-pill-"]',
    )

    forEachNode(missMountPoints, mountPoint => {
      const root = getOrCreateRoot(mountPoint)
      root.render(<Pill color="danger">{I18n.t('missing')}</Pill>)
    })

    forEachNode(lateMountPoints, mountPoint => {
      const root = getOrCreateRoot(mountPoint)
      root.render(<Pill color="info">{I18n.t('late')}</Pill>)
    })

    forEachNode(excusedMountPoints, mountPoint => {
      const root = getOrCreateRoot(mountPoint)
      root.render(<Pill color="danger">{I18n.t('excused')}</Pill>)
    })

    forEachNode(extendedMountPoints, mountPoint => {
      const root = getOrCreateRoot(mountPoint)
      root.render(<Pill color="alert">{I18n.t('extended')}</Pill>)
    })

    forEachNode(customGradeStatusMountPoints, mountPoint => {
      const status =
        statusMap[mountPoint.classList[0].substring('submission-custom-grade-status-pill-'.length)]
      if (status) {
        const root = getOrCreateRoot(mountPoint)
        root.render(<Pill>{status.name}</Pill>)
      }
    })
  },
}
