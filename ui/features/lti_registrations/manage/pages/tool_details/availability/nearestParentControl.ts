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

import type {LtiContextControl} from '../../../model/LtiContextControl'

/**
 *
 * @param controls - An array of LtiContextControl objects.
 * @returns A Map where the keys are the id of a context, prefixed with a for account or c for course,
 * and the values are the corresponding LtiContextControl for that context.
 */
export const buildControlsByPath = (
  controls: LtiContextControl[],
): Map<string, LtiContextControl> =>
  new Map(
    controls.map(cc => {
      if (cc.course_id) {
        return [`c${cc.course_id}`, cc]
      } else {
        return [`a${cc.account_id}`, cc]
      }
    }),
  )

/**
 * Returns the nearest parent control for a given control. This is determined by the path of the control. Note that if
 * the control is a root control, it will not have a parent by definition and undefined will be returned.
 * @param control
 * @param controlsByPath
 * @returns
 */
export const nearestParentControl = (
  control: LtiContextControl,
  controlsByPath: Map<string, LtiContextControl>,
): LtiContextControl | undefined => {
  const possibleAncestors = control.path.split('.').filter(Boolean).slice(0, -1).reverse()
  for (const ancestor of possibleAncestors) {
    const control = controlsByPath.get(ancestor)
    if (control) {
      return control
    }
  }
  return undefined
}
