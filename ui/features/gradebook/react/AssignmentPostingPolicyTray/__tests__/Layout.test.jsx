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

import {render, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import Layout from '../Layout'

jest.mock('@canvas/apollo-v3', () => ({
  createClient: () => ({
    mutate: jest.fn().mockResolvedValue({}),
  }),
  gql: jest.fn(),
}))

describe('AssignmentPostingPolicyTray Layout', () => {
  let container
  let getByRole
  let getByText

  function getCancelButton() {
    return getByRole('button', {name: /^cancel$/i})
  }

  function getSaveButton() {
    return getByRole('button', {name: /^save$/i})
  }

  function getAutomaticallyPostInput() {
    return getByRole('radio', {name: /automatically.*grades.*entered/i})
  }

  function getManuallyPostInput() {
    return getByRole('radio', {name: /manually.*grades.*hidden/i})
  }

  function getLabelWithManualPostingDetail() {
    try {
      return getByText(/while the grades for this assignment are set to manual/i)
    } catch {
      return undefined
    }
  }

  let context
  let user

  beforeEach(() => {
    user = userEvent.setup()
    context = {
      allowAutomaticPosting: true,
      allowCanceling: true,
      allowSaving: true,
      onPostPolicyChanged: jest.fn(),
      onDismiss: jest.fn(),
      onSave: jest.fn(),
      originalPostManually: true,
      selectedPostManually: false,
    }
    const utils = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <Layout {...context} />
      </MockedProvider>
    )
    container = utils.container
    getByRole = utils.getByRole
    getByText = utils.getByText
  })

  afterEach(() => {
    cleanup()
    user = null
    context = null
    container = null
  })

  it('clicking "Cancel" button calls the onDismiss prop', async () => {
    await user.click(getCancelButton())
    expect(context.onDismiss).toHaveBeenCalledTimes(1)
  })

  it('the "Cancel" button is enabled when allowCanceling is true', () => {
    expect(getCancelButton().disabled).toBe(false)
  })

  it('the "Cancel" button is disabled when allowCanceling is false', () => {
    cleanup()
    const newContext = {...context, allowCanceling: false}
    const utils = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <Layout {...newContext} />
      </MockedProvider>
    )
    getByRole = utils.getByRole
    expect(getCancelButton().disabled).toBe(true)
  })

  it('clicking "Save" button calls the onSave prop', async () => {
    await user.click(getSaveButton())
    expect(context.onSave).toHaveBeenCalledTimes(1)
  })

  it('the "Save" button is enabled when allowSaving is true', () => {
    expect(getSaveButton().disabled).toBe(false)
  })

  it('the "Save" button is disabled when allowSaving is false', () => {
    cleanup()
    const newContext = {...context, allowSaving: false}
    const utils = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <Layout {...newContext} />
      </MockedProvider>
    )
    getByRole = utils.getByRole
    expect(getSaveButton().disabled).toBe(true)
  })

  describe('when allowAutomaticPosting is true', () => {
    it('the "Automatically" radio input is enabled', () => {
      expect(getAutomaticallyPostInput().disabled).toBe(false)
    })

    it('the "Manually" radio input is enabled', () => {
      expect(getManuallyPostInput().disabled).toBe(false)
    })
  })

  describe('when allowAutomaticPosting is false', () => {
    beforeEach(() => {
      cleanup()
      const newContext = {...context, allowAutomaticPosting: false}
      const utils = render(
        <MockedProvider mocks={[]} addTypename={false}>
          <Layout {...newContext} />
        </MockedProvider>
      )
      getByRole = utils.getByRole
    })

    it('the "Automatically" radio input is disabled', () => {
      expect(getAutomaticallyPostInput().disabled).toBe(true)
    })

    it('the "Manually" radio input is enabled', () => {
      expect(getManuallyPostInput().disabled).toBe(false)
    })
  })

  describe('when selectedPostManually is true', () => {
    beforeEach(() => {
      cleanup()
      const newContext = {...context, selectedPostManually: true}
      const utils = render(
        <MockedProvider mocks={[]} addTypename={false}>
          <Layout {...newContext} />
        </MockedProvider>
      )
      getByRole = utils.getByRole
      getByText = utils.getByText
    })

    it('the "Manually" radio input is selected', () => {
      expect(getManuallyPostInput().checked).toBe(true)
    })

    it('additional explicatory text on the nature of manual posting is displayed', () => {
      expect(getLabelWithManualPostingDetail()).toBeTruthy()
    })
  })

  describe('when selectedPostManually is false', () => {
    it('the "Automatically" radio input is selected', () => {
      expect(getAutomaticallyPostInput().checked).toBe(true)
    })

    it('no additional text on the nature of manual posting is displayed', () => {
      expect(getLabelWithManualPostingDetail()).toBeUndefined()
    })
  })

  it('clicking the "Manually" input calls onPostPolicyChanged', async () => {
    await user.click(getManuallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledTimes(1)
  })

  it('clicking the "Manually" input passes postManually: true to onPostPolicyChanged', async () => {
    await user.click(getManuallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledWith({postManually: true})
  })

  it('clicking the "Automatically" input calls onPostPolicyChanged', async () => {
    cleanup()
    const newContext = {...context, selectedPostManually: true}
    const utils = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <Layout {...newContext} />
      </MockedProvider>
    )
    getByRole = utils.getByRole
    await user.click(getAutomaticallyPostInput())
    expect(newContext.onPostPolicyChanged).toHaveBeenCalledTimes(1)
  })

  it('clicking the "Automatically" input passes postManually: false to onPostPolicyChanged', async () => {
    cleanup()
    const newContext = {...context, selectedPostManually: true}
    const utils = render(
      <MockedProvider mocks={[]} addTypename={false}>
        <Layout {...newContext} />
      </MockedProvider>
    )
    getByRole = utils.getByRole
    await user.click(getAutomaticallyPostInput())
    expect(newContext.onPostPolicyChanged).toHaveBeenCalledWith({postManually: false})
  })
})
