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

import type {GetLtiAssetProcessorsResult} from '../../../dependenciesShims'
import type {LtiAssetProcessor} from '../../types/LtiAssetProcessors'

export const defaultLtiAssetProcessors: LtiAssetProcessor[] = [
  {
    _id: '1000',
    title: 'MyAssetProcessor1',
    iconOrToolIconUrl: null,
    externalTool: {
      _id: '123',
      name: 'MyTool1',
      labelFor: 'MyToolTitle1',
    },
  },
  {
    _id: '1001',
    title: 'MyAssetProcessor2',
    iconOrToolIconUrl: null,
    externalTool: {
      _id: '124',
      name: 'MyTool2',
      labelFor: 'MyToolTitle2',
    },
  },
]

export const defaultGetLtiAssetProcessorsResult: GetLtiAssetProcessorsResult = {
  assignment: {
    ltiAssetProcessorsConnection: {
      nodes: defaultLtiAssetProcessors,
    },
  },
}
