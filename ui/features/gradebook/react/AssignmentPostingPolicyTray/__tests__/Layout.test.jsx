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
import { render } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Layout from '../Layout'

describe('AssignmentPostingPolicyTray Layout', () => {
  let container
  let context


  function getCancelButton() {
    return [...container.querySelectorAll('button')].find(
      button => button.textContent === 'Cancel'
    )
  }

  function getSaveButton() {
    return [...container.querySelectorAll('button')].find(
      button => button.textContent === 'Save'
    )
  }

  function getLabel(text) {
    return [...container.querySelectorAll('label')].find(label =>
      label.textContent.includes(text)
    )
  }

  function getInputByLabel(label) {
    const labelElement = getLabel(label)
    if (!labelElement) return undefined
    return document.getElementById(labelElement.htmlFor)
  }

  function getAutomaticallyPostInput() {
    return getInputByLabel('Automatically')
  }

  function getManuallyPostInput() {
    return getInputByLabel('Manually')
  }

  function getLabelWithManualPostingDetail() {
    return getLabel('While the grades for this assignment are set to manual')
  }

  beforeEach(() => {
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
    const { container: renderedContainer } = render(<Layout {...context} />)
    container = renderedContainer
  })

  afterEach(() => {
    container = null
  })

  it('clicking "Cancel" button calls the onDismiss prop', async () => {
    await userEvent.click(getCancelButton())
    expect(context.onDismiss).toHaveBeenCalledTimes(1)
  })

  it('the "Cancel" button is enabled when allowCanceling is true', () => {
    expect(getCancelButton().disabled).toBe(false)
  })

  it('the "Cancel" button is disabled when allowCanceling is false', () => {
    context.allowCanceling = false
    const { container: newContainer } = render(<Layout {...context} />)
    container = newContainer
    expect(getCancelButton().disabled).toBe(true)
  })

  it('clicking "Save" button calls the onSave prop', async () => {
    await userEvent.click(getSaveButton())
    expect(context.onSave).toHaveBeenCalledTimes(1)
  })

  it('the "Save" button is enabled when allowSaving is true', () => {
    expect(getSaveButton().disabled).toBe(false)
  })

  it('the "Save" button is disabled when allowSaving is false', () => {
    context.allowSaving = false
    const { container: newContainer } = render(<Layout {...context} />)
    container = newContainer
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
      context.allowAutomaticPosting = false
      const { container: newContainer } = render(<Layout {...context} />)
      container = newContainer
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
      context.selectedPostManually = true
      const { container: newContainer } = render(<Layout {...context} />)
      container = newContainer
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
    await userEvent.click(getManuallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledTimes(1)
  })

  it('clicking the "Manually" input passes postManually: true to onPostPolicyChanged', async () => {
    await userEvent.click(getManuallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledWith({ postManually: true })
  })

  it('clicking the "Automatically" input calls onPostPolicyChanged', async () => {
    context.selectedPostManually = true
    const { container: newContainer } = render(<Layout {...context} />)
    container = newContainer
    await userEvent.click(getAutomaticallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledTimes(1)
  })

  it('clicking the "Automatically" input passes postManually: false to onPostPolicyChanged', async () => {
    context.selectedPostManually = true
    const { container: newContainer } = render(<Layout {...context} />)
    container = newContainer
    await userEvent.click(getAutomaticallyPostInput())
    expect(context.onPostPolicyChanged).toHaveBeenCalledWith({ postManually: false })
  })
})