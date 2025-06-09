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

import {LtiDeployment} from '../../../model/LtiDeployment'

/**
 * Merges a deployment into an array of existing deployments,
 * also merging context_controls if the deployment already exists.
 * @param existingDeployments
 * @param deployment
 * @returns
 */
export const mergeDeployments = (
  existingDeployments: LtiDeployment[],
  deployment: LtiDeployment,
): LtiDeployment[] => {
  const existingDeploymentIndex = existingDeployments.findIndex(d => d.id === deployment.id)
  if (existingDeploymentIndex !== -1) {
    // Merge context_controls
    return Object.assign([], existingDeployments, {
      [existingDeploymentIndex]: {
        ...deployment,
        context_controls: [
          ...(existingDeployments[existingDeploymentIndex].context_controls || []),
          ...(deployment.context_controls || []),
        ],
      },
    })
  } else {
    // Add new deployment
    return [...existingDeployments, deployment]
  }
}
