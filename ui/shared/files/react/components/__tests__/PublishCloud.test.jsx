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

import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import $ from 'jquery'
import 'jquery-migrate'
import PublishCloud from '@canvas/files/react/components/PublishCloud'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'

describe('PublishCloud', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    $('.ui-dialog').remove()
  })

  afterEach(() => {
    document.body.removeChild(container)
    $('#ui-datepicker-div').empty()
    $('.ui-dialog').remove()
  })

  describe('when user can edit files', () => {
    it('updates publish state when model changes', () => {
      const model = new FilesystemObject({
        locked: true,
        hidden: false,
        id: 42,
      })
      model.url = () => `/api/v1/folders/${model.id}`

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      expect(getByTestId('unpublished-button')).toBeInTheDocument()

      model.set('locked', false)
      expect(getByTestId('published-button')).toBeInTheDocument()
    })

    it('opens restricted dialog when clicking publish cloud', async () => {
      const model = new FilesystemObject({
        locked: true,
        hidden: false,
        id: 42,
      })
      model.url = () => `/api/v1/folders/${model.id}`

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      const button = getByTestId('unpublished-button')
      fireEvent.click(button)

      await waitFor(() => {
        expect($('.ui-dialog')).toHaveLength(1)
      })
    })

    it('toggles between published and unpublished states', () => {
      const model = new FilesystemObject({
        locked: false,
        hidden: false,
        id: 42,
      })
      model.url = () => `/api/v1/folders/${model.id}`

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      const button = getByTestId('published-button')
      fireEvent.click(button)

      model.set('locked', true)
      expect(getByTestId('unpublished-button')).toBeInTheDocument()
    })
  })

  describe('student view', () => {
    it('displays non-clickable restricted dates icon', () => {
      const model = new FilesystemObject({
        locked: false,
        hidden: true,
        lock_at: '2014-02-01',
        unlock_at: '2014-01-01',
        id: 42,
      })
      model.url = () => `/api/v1/folders/${model.id}`

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={false}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      const status = getByTestId('restricted-status')
      expect(status).toHaveAttribute(
        'title',
        'Available after Jan 1, 2014 at 12am until Feb 1, 2014 at 12am',
      )
    })
  })

  describe('initial state', () => {
    it('sets published state based on model locked property', () => {
      const model = new FilesystemObject({
        locked: false,
        id: 42,
      })

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      expect(getByTestId('published-button')).toBeInTheDocument()
    })

    it('sets restricted state when lock_at/unlock_at is present', () => {
      const model = new FilesystemObject({
        hidden: false,
        lock_at: '123',
        unlock_at: '123',
        id: 42,
      })

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      expect(getByTestId('restricted-button')).toBeInTheDocument()
    })
  })

  describe('state extraction', () => {
    it('correctly extracts state from model', () => {
      const model = new FilesystemObject({
        locked: false,
        hidden: true,
        lock_at: null,
        unlock_at: null,
      })

      const {getByTestId} = render(
        <PublishCloud
          model={model}
          userCanEditFilesForContext={true}
          usageRightsRequiredForContext={false}
        />,
        {container},
      )

      expect(getByTestId('hidden-button')).toBeInTheDocument()
    })
  })
})
