/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {act, fireEvent, render, waitForElement} from 'react-testing-library'

import Bridge from '../../../../bridge/Bridge'
import * as fakeSource from '../../../../sidebar/sources/fake'
import CanvasContentTray from '../CanvasContentTray'

describe('RCE Plugins > CanvasContentTray', () => {
  let component
  let props

  beforeEach(() => {
    props = {
      bridge: new Bridge(),
      source: fakeSource
    }
  })

  function renderComponent() {
    component = render(<CanvasContentTray {...props} />)
  }

  function getTray() {
    return component.queryByRole('dialog')
  }

  async function showTrayForPlugin(plugin) {
    act(() => {
      props.bridge.controller.showTrayForPlugin(plugin)
    })
    await waitForElement(getTray)
  }

  function selectContentType(contentTypeLabel) {
    const contentTypeField = component.getByLabelText('Content Type')
    fireEvent.click(contentTypeField)
    fireEvent.click(component.getByText(contentTypeLabel))
  }

  function getContentSubtypeField() {
    return component.queryByLabelText('Content Subtype')
  }

  function selectContentSubtype(contentSubtypeLabel) {
    const contentTypeField = getContentSubtypeField()
    fireEvent.click(contentTypeField)
    fireEvent.click(component.getByText(contentSubtypeLabel))
  }

  describe('Tray Label', () => {
    beforeEach(renderComponent)

    function getTrayLabel() {
      return getTray().getAttribute('aria-label')
    }

    it('is labeled with "Course Links" when using the "links" content type', async () => {
      await showTrayForPlugin('links')
      expect(getTrayLabel()).toEqual('Course Links')
    })

    it('is labeled with "Course Images" when using the "images" content type', async () => {
      await showTrayForPlugin('images')
      expect(getTrayLabel()).toEqual('Course Images')
    })

    it('is labeled with "Course Media" when using the "media" content type', async () => {
      await showTrayForPlugin('media')
      expect(getTrayLabel()).toEqual('Course Media')
    })

    it('is labeled with "Course Documents" when using the "documents" content type', async () => {
      await showTrayForPlugin('documents')
      expect(getTrayLabel()).toEqual('Course Documents')
    })
  })
})
