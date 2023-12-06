// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import PostGradesApp from '../../../SISGradePassback/PostGradesApp'
import EnhancedActionMenu from '../EnhancedActionMenu'
import GradebookExportManager from '../../../shared/GradebookExportManager'
import {waitFor, act, render, fireEvent} from '@testing-library/react'
import React from 'react'

const defaultResult = {
  attachmentUrl: 'http://attachmentUrl',
  updatedAt: '2009-01-20T17:00:00Z',
}

const getPromise = (type, object = defaultResult) => {
  if (type === 'resolved') {
    return Promise.resolve(object)
  }
  return Promise.reject(new Error('Export failure reason'))
}

const workingMenuProps = () => ({
  getAssignmentOrder() {},
  getStudentOrder() {},
  gradebookIsEditable: true,
  contextAllowsGradebookUploads: true,
  gradebookImportUrl: 'http://gradebookImportUrl',

  currentUserId: '42',
  gradebookExportUrl: 'http://gradebookExportUrl',

  postGradesLtis: [
    {
      id: '1',
      name: 'Pinnacle',
      onSelect() {},
    },
  ],

  postGradesFeature: {
    enabled: false,
    label: '',
    store: {},
    returnFocusTo: {focus() {}},
  },

  publishGradesToSis: {
    isEnabled: false,
  },

  gradingPeriodId: '1234',

  showStudentFirstLastName: true,
  updateExportState: () => {},
  setExportManager: () => {},
})

const previousExportProps = () => ({
  lastExport: {
    progressId: '9000',
    workflowState: 'completed',
  },
  attachment: {
    id: '691',
    downloadUrl: 'http://downloadUrl',
    updatedAt: '2009-01-20T17:00:00Z',
    createdAt: '2009-01-20T17:00:00Z',
  },
})

describe('EnhancedActionMenu', () => {
  let component
  let props

  const renderComponent = props_ => {
    return render(<EnhancedActionMenu {...props_} />)
  }

  const clickElement = (role, name) => {
    fireEvent.click(component.getByRole(role, {name}))
  }

  const clickOnDropdown = name => {
    clickElement('button', name)
  }

  const selectDropdownOption = name => {
    clickElement('menuitem', name)
  }

  const {location} = window

  beforeEach(() => {
    props = {
      ...workingMenuProps(),
    }

    delete window.location
    window.location = {
      href: '',
    }
  })

  afterEach(() => {
    window.location = location
  })

  describe('Basic Rendering', () => {
    beforeEach(() => {
      props = {
        ...workingMenuProps(),
        ...previousExportProps(),
      }
    })

    it('renders the keyboard shortcut button when the disable keyboard shortcut setting is turned off', async () => {
      // EVAL-3711 Remove ICE Evaluate feature flag
      window.ENV.FEATURES.instui_nav = true
      const {getByTestId} = renderComponent(props)
      expect(getByTestId('keyboard-shortcuts')).toBeInTheDocument()
    })

    it('does not render the keyboard shortcut button when the disable keyboard shortcut setting is turned on', async () => {
      // EVAL-3711 Remove ICE Evaluate feature flag
      window.ENV.FEATURES.instui_nav = true
      ENV.disable_keyboard_shortcuts = true
      const {queryByTestId} = renderComponent(props)
      expect(queryByTestId('keyboard-shortcuts')).not.toBeInTheDocument()
    })

    it('renders the Import button', async () => {
      component = renderComponent(props)
      const specificMenuItem = component.container.querySelector('[data-menu-id="import"]')
      expect(specificMenuItem).toHaveTextContent('Import')
    })

    it('renders the Export Current Gradebook View menu item', async () => {
      component = renderComponent(props)
      clickOnDropdown('Export')
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Export Current Gradebook View',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('renders the Export Entire Gradebook menu item', async () => {
      component = renderComponent(props)
      clickOnDropdown('Export')
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Export Entire Gradebook',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('renders the Previous export menu item', async () => {
      component = renderComponent(props)
      clickOnDropdown('Export')
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Previous Export (Jan 20, 2009 at 5pm)',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('updates the Previous Export date when export success', async () => {
      const exportResult = getPromise('resolved', {
        ...defaultResult,
        updatedAt: '2021-05-12T13:00:00Z',
      })
      const startExport = jest.spyOn(GradebookExportManager.prototype, 'startExport')
      startExport.mockReturnValue(exportResult)
      component = renderComponent(props)
      clickOnDropdown('Export')
      selectDropdownOption('Export Entire Gradebook')
      await waitFor(() => {
        clickOnDropdown('Export')
      })
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Previous Export (May 12, 2021 at 1pm)',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('previous export date stays the same after updatedAt is changed', async () => {
      props.attachment.updatedAt = '2021-05-12T13:00:00Z'
      component = renderComponent(props)
      clickOnDropdown('Export')
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Previous Export (Jan 20, 2009 at 5pm)',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('renders the Sync Grades LTI menu items', async () => {
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Sync to Pinnacle',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('renders no Post Grades feature menu item when disabled', async () => {
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="post_grades_feature_tool"]')
      expect(specificMenuItem).not.toBeInTheDocument()
    })

    it('renders the Post Grades feature menu item when enabled', async () => {
      props = {...workingMenuProps()}
      props.postGradesFeature.enabled = true
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="post_grades_feature_tool"]')
      expect(specificMenuItem).toHaveTextContent('Sync to SIS')
    })

    it('renders the Post Grades feature menu item with label when sis handle is set', async () => {
      props = {...workingMenuProps()}
      props.postGradesFeature.enabled = true
      props.postGradesFeature.label = 'Powerschool'
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="post_grades_feature_tool"]')
      expect(specificMenuItem).toHaveTextContent('Sync to Powerschool')
    })
  })

  describe('handleExport', () => {
    let startExport
    beforeEach(() => {
      props = {
        ...workingMenuProps(),
      }
      startExport = jest.spyOn(GradebookExportManager.prototype, 'startExport')
      component = renderComponent(props)
      clickOnDropdown('Export')
    })

    it('shows a message to the user indicating the export is in progress', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      const spy = jest.spyOn(window.$, 'flashMessage').mockReturnValue(true)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        expect(spy).toHaveBeenCalled()
        expect(spy.mock.calls[0][0]).toEqual(
          'Gradebook export has started. This may take a few minutes.'
        )
      })
    })

    it('changes the "Export Current Gradebook View" and "Export Entire Gradebook" menu items to indicate the export is in progress', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      clickOnDropdown('Export')
      const specificMenuItems = component.getAllByRole('menuitem', {name: /Export in progress/})
      await waitFor(() => {
        expect(specificMenuItems[0]).toBeInTheDocument()
        expect(specificMenuItems[1]).toBeInTheDocument()
        expect(specificMenuItems[0]).toHaveAttribute('aria-disabled', 'true')
        expect(specificMenuItems[1]).toHaveAttribute('aria-disabled', 'true')
      })
    })

    it('starts the export using the GradebookExportManager instance', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        expect(startExport).toHaveBeenCalled()
      })
    })

    it('passes the grading period to the GradebookExportManager', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        expect(startExport.mock.calls[0][0]).toEqual('1234')
      })
    })

    it('passes showStudentFirstLastName to the GradebookExportManager', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        expect(startExport.mock.calls[0][2]).toEqual(true)
      })
    })

    it('on success, takes the user to the newly completed export', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => expect(window.location.href).toEqual(defaultResult.attachmentUrl))
    })

    it('on success, re-enables the "Export Entire Gradebook" menu item', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Entire Gradebook')
      })
      await waitFor(() => {
        clickOnDropdown('Export')
      })
      const specificMenuItem = document
        .querySelector('[data-menu-id="export-all"]')
        ?.closest('[role="menuitem"]')
      await waitFor(() => {
        expect(specificMenuItem).toHaveTextContent('Export Entire Gradebook')
        expect(specificMenuItem).not.toHaveAttribute('aria-disabled', 'true')
      })
    })

    it('on success, re-enables the "Export Current Gradebook View" menu item', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        clickOnDropdown('Export')
      })
      const specificMenuItem = document
        .querySelector('[data-menu-id="export"]')
        ?.closest('[role="menuitem"]')
      await waitFor(() => {
        expect(specificMenuItem).toHaveTextContent('Export Current Gradebook View')
        expect(specificMenuItem).not.toHaveAttribute('aria-disabled', 'true')
      })
    })

    it('on success, shows a message that the export has completed', async () => {
      const exportResult = getPromise('resolved')
      startExport.mockReturnValue(exportResult)
      const messageSpy = jest.spyOn(window.$, 'flashMessage').mockReturnValue(true)
      const handleUpdateSpyTimeout = jest.spyOn(global, 'setTimeout')

      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        clickOnDropdown('Export')
      })
      await waitFor(() => {
        expect(messageSpy).toHaveBeenCalled()
        expect(messageSpy.mock.calls[0][0]).toEqual(
          'Gradebook export has started. This may take a few minutes.'
        )
        expect(messageSpy.mock.calls[1][0]).toEqual('Gradebook export has completed')
        expect(handleUpdateSpyTimeout).toHaveBeenCalled()
      })
    })

    it('on failure, shows a message to the user indicating the export failed', async () => {
      const spy = jest.spyOn(window.$, 'flashError').mockReturnValue(true)
      const exportResult = getPromise('rejected')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        expect(spy).toHaveBeenCalled()
        expect(spy.mock.calls[0][0]).toEqual(
          'Gradebook Export Failed: Error: Export failure reason'
        )
      })
    })

    it('on failure, renables the "Export Current Gradebook View" and "Export Entire Gradebook" menu items', async () => {
      const exportResult = getPromise('rejected')
      startExport.mockReturnValue(exportResult)
      act(() => {
        selectDropdownOption('Export Current Gradebook View')
      })
      await waitFor(() => {
        clickOnDropdown('Export')
      })
      const exportMenuItem = document
        .querySelector('[data-menu-id="export"]')
        ?.closest('[role="menuitem"]')
      const exportAllMenuItem = document
        .querySelector('[data-menu-id="export-all"]')
        ?.closest('[role="menuitem"]')
      await waitFor(() => {
        expect(exportMenuItem).toHaveTextContent('Export Current Gradebook View')
        expect(exportMenuItem).not.toHaveAttribute('aria-disabled', 'true')
        expect(exportAllMenuItem).toHaveTextContent('Export Entire Gradebook')
        expect(exportAllMenuItem).not.toHaveAttribute('aria-disabled', 'true')
      })
    })
  })

  describe('handleImport', () => {
    beforeEach(() => {
      component = renderComponent(props)
    })

    it('it takes you to the new imports page', async () => {
      clickOnDropdown('Import')
      expect(window.location.href).toEqual(props.gradebookImportUrl)
    })
  })

  describe('disableImports', () => {
    it('disables interaction with "Import" button when gradebook is not editable and context allows gradebook uploads', async () => {
      props = {
        ...workingMenuProps(),
        gradebookIsEditable: false,
      }
      component = renderComponent(props)
      const specificMenuItem = document.querySelector('[data-menu-id="import"]')?.closest('button')
      expect(specificMenuItem).toHaveAttribute('disabled', '')
    })

    it('disables interaction with "Import" when gradebook is editable but context does not allow gradebook uploads', async () => {
      props = {
        ...workingMenuProps(),
        contextAllowsGradebookUploads: false,
      }
      component = renderComponent(props)
      const specificMenuItem = document.querySelector('[data-menu-id="import"]')?.closest('button')
      expect(specificMenuItem).toHaveAttribute('disabled', '')
    })
  })

  describe('post grade Ltis', () => {
    beforeEach(() => {
      props.postGradesLtis[0].onSelect = jest.fn()
      component = renderComponent(props)
      clickOnDropdown('Sync')
    })

    it('draws with "Sync to" label', async () => {
      const specificMenuItem = component.getByRole('menuitem', {
        name: 'Sync to Pinnacle',
      })
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('invokes the onSelect prop when selected', async () => {
      selectDropdownOption('Sync to Pinnacle')
      expect(props.postGradesLtis[0].onSelect).toHaveBeenCalled()
    })
  })

  describe('post grade feature', () => {
    beforeEach(() => {
      props.postGradesFeature.enabled = true
      props.postGradesLtis[0].onSelect = jest.fn()

      component = renderComponent(props)
      clickOnDropdown('Sync')
    })

    it('launches the PostGrades App when selected', async () => {
      jest.useFakeTimers()
      const appLaunch = jest.spyOn(PostGradesApp, 'AppLaunch').mockReturnValue(true)
      selectDropdownOption('Sync to SIS')
      setTimeout(() => {
        expect(appLaunch).toHaveBeenCalled()
      }, 15)
      jest.runAllTimers()
    })
  })

  describe('publish grades to SIS', () => {
    beforeEach(() => {
      props.postGradesLtis[0].onSelect = jest.fn()
    })

    it('does not render menu item when isEnabled is false and publishToSisUrl is undefined', async () => {
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="publish-grades-to-sis"]')
      expect(specificMenuItem).not.toBeInTheDocument()
    })

    it('does not render menu item when isEnabled is true and publishToSisUrl is undefined', async () => {
      props = {
        ...props,
        publishGradesToSis: {
          isEnabled: true,
        },
      }
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="publish-grades-to-sis"]')
      expect(specificMenuItem).not.toBeInTheDocument()
    })

    it('renders menu item when isEnabled is true and publishToSisUrl is defined', async () => {
      props = {
        ...props,
        publishGradesToSis: {
          isEnabled: true,
          publishToSisUrl: 'http://example.com',
        },
      }
      component = renderComponent(props)
      clickOnDropdown('Sync')
      const specificMenuItem = document.querySelector('[data-menu-id="publish-grades-to-sis"]')
      expect(specificMenuItem).toBeInTheDocument()
    })

    it('calls gotoUrl with publishToSisUrl when clicked', async () => {
      props = {
        ...workingMenuProps(),
        publishGradesToSis: {
          isEnabled: true,
          publishToSisUrl: 'http://example.com',
        },
      }
      component = renderComponent(props)
      clickOnDropdown('Sync')
      selectDropdownOption('Sync grades to SIS')
      expect(window.location.href).toEqual(props.publishGradesToSis.publishToSisUrl)
    })
  })
})
