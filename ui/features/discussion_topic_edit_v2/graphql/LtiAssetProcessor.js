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

import {number, shape, string} from 'prop-types'
import {gql} from '@apollo/client'

export const LtiAssetProcessor = {
  fragment: gql`
    fragment EditV2LtiAssetProcessor on LtiAssetProcessor {
      _id
      title
      text
      externalTool {
        _id
        name
        labelFor(placement: ActivityAssetProcessor)
      }
      iconOrToolIconUrl,
      iframe {
        width
        height
      }
      window {
        width
        height
        targetName
        windowFeatures
      }
    }
  `,
  shape: () => ({
    // See ExistingAttachedAssetProcessorGraphql in
    // ui/shared/lti/model/AssetProcessor.ts
    // for the types.
    _id: string,
    title: string,
    text: string,
    externalTool: shape({
      _id: string,
      name: string,
      labelFor: string,
    }),
    iconOrToolIconUrl: string,
    iframe: shape({
      width: number,
      height: number,
    }),
    window: shape({
      width: number,
      height: number,
      targetName: string,
      windowFeatures: string,
    }),
  }),
  mock: ({
    _id = '1',
    title = 'My Mock LTI Asset Processor',
    text = 'This is a mock LTI Asset Processor',
    externalTool = {
      _id: '1',
      name: 'Mock Tool',
      labelFor: 'Mock Tool Label',
    },
    iconOrToolIconUrl = 'https://example.com/icon.png',
    iframe = {
      width: 800,
      height: 600,
    },
    window = {
      width: 800,
      height: 600,
      targetName: 'lti-window',
      windowFeatures: 'resizable=yes,scrollbars=yes',
    },
  } = {}) => ({
    _id,
    title,
    text,
    externalTool,
    iconOrToolIconUrl,
    iframe,
    window,
  }),
}
