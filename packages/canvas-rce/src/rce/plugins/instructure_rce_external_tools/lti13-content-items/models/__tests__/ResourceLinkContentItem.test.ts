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

import ResourceLinkContentItem from '../ResourceLinkContentItem'
import {ResourceLinkContentItemJson} from '../../Lti13ContentItemJson'
import {RceLti13ContentItemContext} from '../../RceLti13ContentItem'

const endpoint = 'http://test.canvas.com/accounts/1/external_tools/retrieve'
const title = 'Tool Title'
const lookup_uuid = '0b8fbc86-fdd7-4950-852d-ffa789b37ff2'
const json: ResourceLinkContentItemJson = {
  type: 'ltiResourceLink',
  title,
  lookup_uuid,
}

function resourceLinkContentItem(
  overrides: Partial<ResourceLinkContentItemJson>,
  context: Partial<RceLti13ContentItemContext> = {}
) {
  const mergedJson = {...json, ...overrides}
  return new ResourceLinkContentItem(mergedJson, {
    selection: context.selection ?? null,
    ltiEndpoint: context.ltiEndpoint ?? null,
    containingCanvasLtiToolId: context.containingCanvasLtiToolId ?? null,
    ltiIframeAllowPolicy: context.ltiIframeAllowPolicy ?? null,
  })
}

describe('ResourceLinkContentItem', () => {
  describe('constructor', () => {
    it('sets the url to the canvas launch endpoint', () => {
      expect(resourceLinkContentItem({}, {ltiEndpoint: endpoint}).buildUrl()).toEqual(
        `${endpoint}?display=borderless&resource_link_lookup_uuid=0b8fbc86-fdd7-4950-852d-ffa789b37ff2`
      )
    })

    it('includes the containingCanvasLtiToolId if provided', () => {
      expect(
        resourceLinkContentItem(
          {},
          {ltiEndpoint: endpoint, containingCanvasLtiToolId: 'sometool'}
        ).buildUrl()
      ).toEqual(
        `${endpoint}?display=borderless&resource_link_lookup_uuid=0b8fbc86-fdd7-4950-852d-ffa789b37ff2&parent_frame_context=sometool`
      )
    })
  })

  describe('when the iframe property is specified', () => {
    const iframe = {
      src: 'http://www.instructure.com',
      width: 500,
      height: 200,
    }

    it('returns markup for an iframe', () => {
      expect(
        resourceLinkContentItem(
          {iframe},
          {
            ltiEndpoint: 'http://somewhere.canvas/path',
            ltiIframeAllowPolicy: 'allow',
          }
        ).toHtmlString()
      ).toEqual(
        '<iframe src="http://somewhere.canvas/path?display=in_rce&amp;resource_link_lookup_uuid=0b8fbc86-fdd7-4950-852d-ffa789b37ff2" title="Tool Title" allowfullscreen="true" allow="allow" style="width: 500px; height: 200px;"></iframe>'
      )
    })
  })
})
