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

import type {LtiDeployment} from '../../../model/LtiDeployment'

/**
 *
 * @param deployment - The LTI deployment for which to find the root context control.
 * @throws Error if no root context control is found for the given deployment.
 * @returns The root context control for the given deployment. Undefined if not found.
 */
export const findRootContextControl = (deployment: LtiDeployment) => {
  const contextControls = deployment.context_controls || []
  const rootControl = contextControls.find(cc => {
    return (
      (deployment.context_type === 'Course' && cc.course_id === deployment.context_id) ||
      (deployment.context_type === 'Account' && cc.account_id === deployment.context_id)
    )
  })

  if (!rootControl) {
    throw new Error(
      `No root context control found for deployment ${deployment.id} in context ${deployment.context_id} of type ${deployment.context_type}. All deployments must have a root context control in the same context as themselves.`,
    )
  }
  return rootControl
}
