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

import $ from 'jquery'
import React from 'react'
import {userEvent} from '@testing-library/user-event'
import {render, screen, waitFor} from '@testing-library/react'
import PostGradesApp from '../../../SISGradePassback/PostGradesApp'
import GradebookExportManager from '../../../shared/GradebookExportManager'
import ActionMenu from '../ActionMenu'
import {getActionMenuProps} from './helpers'

let props: any = {}

describe('ActionMenu', () => {
  beforeEach(() => {
    props = getActionMenuProps()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('Basic Rendering', () => {
    async function subject(specific_properties: any) {
      render(<ActionMenu {...specific_properties} />)
      const actionButton = screen.getByText('Actions')
      await userEvent.click(actionButton)
    }

    test('renders the Import menu item', async () => {
      await subject(props)
      expect(screen.getByText('Import')).toBeInTheDocument()
    })

    test('renders the Export Current Gradebook View menu item', async () => {
      await subject(props)
      const exportMenuItem = screen.getByText('Export Current Gradebook View')
      expect(exportMenuItem).toBeInTheDocument()
      expect(exportMenuItem.parentElement).not.toHaveAttribute('aria-disabled')
    })

    test('renders the Export Entire Gradebook menu item', async () => {
      await subject(props)
      const exportAllMenuItem = screen.getByText('Export Entire Gradebook')
      expect(exportAllMenuItem).toBeInTheDocument()
      expect(exportAllMenuItem.parentElement).not.toHaveAttribute('aria-disabled')
    })

    test('renders the Previous export menu item regardless of updated_at', async () => {
      props.attachment.updatedAt = '2021-05-12T13:00:00Z'
      await subject(props)
      expect(screen.getByText('Previous Export (Jan 20, 2009 at 5pm)')).toBeInTheDocument()
    })

    test('renders the Sync Grades LTI menu items', async () => {
      await subject(props)
      expect(screen.getByText('Sync to Pinnacle')).toBeInTheDocument()
    })

    test('renders no Post Grades feature menu item when disabled', async () => {
      await subject(props)
      const postGradesMenuItem = screen.queryByText('Sync to SIS')
      expect(postGradesMenuItem).not.toBeInTheDocument()
    })

    test('renders the Post Grades feature menu item when enabled', async () => {
      props.postGradesFeature.enabled = true
      await subject(props)
      const postGradesMenuItem = screen.getByText('Sync to SIS')
      expect(postGradesMenuItem).toBeInTheDocument()
    })

    test('renders the Post Grades feature menu item with label when sis handle is set', async () => {
      props.postGradesFeature.enabled = true
      props.postGradesFeature.label = 'Powerschool'
      await subject(props)
      const postGradesMenuItem = screen.getByText('Sync to Powerschool')
      expect(postGradesMenuItem).toBeInTheDocument()
    })
  })

  describe('getExistingExport', () => {
    beforeEach(() => {
      props = getActionMenuProps()
    })

    test('returns an export hash with workflowState when progressId and attachment.id are present', function () {
      const myRef: any = React.createRef()
      render(<ActionMenu {...props} ref={myRef} />)
      expect(myRef.current.getExistingExport()).toEqual({
        attachmentId: '691',
        progressId: '9000',
        workflowState: 'completed',
      })
    })

    test('returns undefined when lastExport is undefined', function () {
      props.lastExport = undefined
      const myRef: any = React.createRef()
      render(<ActionMenu {...props} ref={myRef} />)
      expect(myRef.current.getExistingExport()).toEqual(undefined)
    })

    test("returns undefined when lastExport's attachment is undefined", function () {
      props.attachment = undefined
      const myRef: any = React.createRef()
      render(<ActionMenu {...props} ref={myRef} />)
      expect(myRef.current.getExistingExport()).toEqual(undefined)
    })

    test('returns undefined when lastExport is missing progressId', function () {
      props.lastExport = {progressId: undefined, workflowState: 'completed'}
      const myRef: any = React.createRef()
      render(<ActionMenu {...props} ref={myRef} />)
      expect(myRef.current.getExistingExport()).toEqual(undefined)
    })

    test("returns undefined when lastExport's attachment is missing its id", function () {
      props.attachment = {
        id: undefined,
        downloadUrl: 'http://downloadUrl',
        updatedAt: '2009-01-20T17:00:00Z',
        createdAt: '2009-01-20T17:00:00Z',
      }
      const myRef: any = React.createRef()
      render(<ActionMenu {...props} ref={myRef} />)
      expect(myRef.current.getExistingExport()).toEqual(undefined)
    })
  })

  describe('handleExport', () => {
    async function subject(specific_properties: any) {
      render(<ActionMenu {...specific_properties} />)
      await userEvent.click(screen.getByText('Actions'))
      await userEvent.click(screen.getByText('Export Current Gradebook View'))
      await userEvent.click(screen.getByText('Actions'))
    }

    test('Runs the export and updates the UI accordingly', async function () {
      GradebookExportManager.prototype.startExport = jest.fn(() =>
        Promise.resolve({
          attachmentUrl: 'http://attachmentUrl',
          updatedAt: '2009-01-20T17:00:00Z',
        })
      )
      $.flashMessage = jest.fn()
      const spy = jest.spyOn(ActionMenu, 'gotoUrl')
      await subject(props)
      expect(screen.getByText('New Export (Jan 20, 2009 at 5pm)')).toBeInTheDocument()
      expect(GradebookExportManager.prototype.startExport).toHaveBeenCalledWith(
        '1234',
        expect.anything(),
        undefined,
        expect.anything(),
        true
      )
      expect($.flashMessage).toHaveBeenCalledWith(
        'Gradebook export has started. This may take a few minutes.'
      )
      expect($.flashMessage).toHaveBeenCalledWith('Gradebook export has completed')
      expect(spy).toHaveBeenCalledWith('http://attachmentUrl')
    })

    test('handleResumeExport will resume the export with success', async function () {
      GradebookExportManager.prototype.monitorExport = jest.fn()
      props.lastExport = {progressId: '9000', workflowState: 'queued'}
      await subject(props)
      expect(GradebookExportManager.prototype.monitorExport).toHaveBeenCalledTimes(1)
    })

    test('On failure, shows an error and reenables the export buttons', async function () {
      GradebookExportManager.prototype.startExport = jest.fn(() =>
        Promise.reject(new Error('Mocked failure'))
      )
      $.flashError = jest.fn()
      await subject(props)
      expect($.flashError).toHaveBeenCalledWith('Gradebook Export Failed: Error: Mocked failure')
      expect(screen.getByText('Export Current Gradebook View')).toBeInTheDocument()
    })
  })

  describe('handleImport', () => {
    async function subject(specific_properties: any) {
      render(<ActionMenu {...specific_properties} />)
      await userEvent.click(screen.getByText('Actions'))
      await userEvent.click(screen.getByText('Import'))
    }

    test('it takes you to the new imports page', async function () {
      const spy = jest.spyOn(ActionMenu, 'gotoUrl')
      props.gradebookImportUrl = 'http://importpage'
      await subject(props)
      expect(spy).toHaveBeenCalledWith('http://importpage')
    })
  })

  describe('disableImports', () => {
    function subject(specific_properties: any, ref: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
    }

    test('is called once when the component renders', function () {
      jest.spyOn(ActionMenu.prototype, 'disableImports').mockImplementation(() => false)
      const ref = React.createRef()
      subject(props, ref)
      expect(ActionMenu.prototype.disableImports).toHaveBeenCalledTimes(1)
    })

    test('returns false when gradebook is editable and context allows gradebook uploads', async function () {
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ref.current.disableImports()).toEqual(false)
    })

    test('returns true when gradebook is not editable and context allows gradebook uploads', function () {
      props.gradebookIsEditable = false
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ref.current.disableImports()).toBeTruthy()
    })
  })

  describe('lastExportFromProps', () => {
    function subject(specific_properties: any, ref: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
    }

    test('returns the lastExport hash if props have a completed last export', function () {
      props.lastExport = {progressId: '9000', workflowState: 'completed'}
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ref.current.lastExportFromProps()).toEqual({
        progressId: '9000',
        workflowState: 'completed',
      })
    })

    test('returns undefined if props have no lastExport', function () {
      props.lastExport = undefined
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ref.current.lastExportFromProps()).toEqual(undefined)
    })

    test('returns undefined if props have a lastExport but it is not completed', function () {
      props.lastExport = {progressId: '9000', workflowState: 'discombobulated'}
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ref.current.lastExportFromProps()).toEqual(undefined)
    })
  })

  describe('lastExportFromState', () => {
    function subject(specific_properties: any, ref: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
    }

    test('returns the previous export if state has a previousExport defined', function () {
      const expectedPreviousExport = {
        label: 'previous export label',
        attachmentUrl: 'http://attachmentUrl',
      }
      const ref: any = React.createRef()
      subject(props, ref)
      ref.current.setState({previousExport: expectedPreviousExport})
      expect(ref.current.lastExportFromState()).toEqual(expectedPreviousExport)
    })

    test('returns undefined if an export is already in progress', function () {
      const ref: any = React.createRef()
      subject(props, ref)
      ref.current.setExportInProgress(true)
      expect(ref.current.lastExportFromState()).toEqual(undefined)
    })

    test('returns undefined if no previous export is set in the state', function () {
      const ref: any = React.createRef()
      subject(props, ref)
      ref.current.setState({previousExport: undefined})
      ref.current.setExportInProgress(false)
      expect(ref.current.lastExportFromState()).toEqual(undefined)
    })
  })

  describe('previousExport', () => {
    function subject(specific_properties: any, ref: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
    }

    test('returns the previous export stored in the state if it is available', function () {
      jest.spyOn(ActionMenu.prototype, 'lastExportFromState').mockImplementation(() => {
        return {
          label: 'previous export label',
          attachmentUrl: 'http://attachmentUrl',
        }
      })
      const ref: any = React.createRef()
      subject(props, ref)
      expect(ActionMenu.prototype.lastExportFromState).toHaveBeenCalledTimes(1)
      expect(ref.current.previousExport()).toEqual({
        label: 'previous export label',
        attachmentUrl: 'http://attachmentUrl',
      })
      expect(ActionMenu.prototype.lastExportFromState).toHaveBeenCalledTimes(2)
    })

    test('returns the previous export stored in the props if nothing is available in state', function () {
      const ref: any = React.createRef()
      const expectedPreviousExport = {
        attachmentUrl: 'http://downloadUrl',
        label: 'Previous Export (Jan 20, 2009 at 5pm)',
      }
      subject(props, ref)
      jest.spyOn(ActionMenu.prototype, 'lastExportFromState').mockImplementation(() => {
        return undefined
      })
      jest.spyOn(ActionMenu.prototype, 'lastExportFromProps').mockImplementation(() => {
        return {expectedPreviousExport, progressId: '9000', workflowState: 'completed'}
      })
      expect(ref.current.previousExport()).toEqual(expectedPreviousExport)
      expect(ActionMenu.prototype.lastExportFromState).toHaveBeenCalledTimes(1)
      expect(ActionMenu.prototype.lastExportFromProps).toHaveBeenCalledTimes(1)
    })

    test('returns undefined if state has nothing and props have nothing', function () {
      const ref: any = React.createRef()
      const returnUndefined = () => {
        return undefined
      }
      subject(props, ref)
      jest.spyOn(ActionMenu.prototype, 'lastExportFromState').mockImplementation(returnUndefined)
      jest.spyOn(ActionMenu.prototype, 'lastExportFromProps').mockImplementation(returnUndefined)
      expect(ref.current.previousExport()).toEqual(undefined)
      expect(ActionMenu.prototype.lastExportFromState).toHaveBeenCalledTimes(1)
      expect(ActionMenu.prototype.lastExportFromProps).toHaveBeenCalledTimes(1)
    })
  })

  describe('exportInProgress', () => {
    function subject(specific_properties: any, ref: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
    }

    test('returns true if exportInProgress is set', function () {
      const ref: any = React.createRef()
      subject(props, ref)
      ref.current.setExportInProgress(true)
      expect(ref.current.exportInProgress()).toEqual(true)
    })

    test('returns false if exportInProgress is set to false', function () {
      const ref: any = React.createRef()
      subject(props, ref)
      ref.current.setExportInProgress(false)
      expect(ref.current.exportInProgress()).toEqual(false)
    })
  })

  describe('Post Grade Ltis', () => {
    async function subject(specific_properties: any, ref?: any) {
      render(<ActionMenu {...specific_properties} ref={ref} />)
      const actionButton = screen.getByText('Actions')
      await userEvent.click(actionButton)
    }

    test('Invokes the onSelect prop when selected', async function () {
      props.postGradesLtis[0].onSelect = jest.fn()
      await subject(props)
      const syncButton = screen.getByText('Sync to Pinnacle')
      await userEvent.click(syncButton)
      expect(props.postGradesLtis[0].onSelect).toHaveBeenCalledTimes(1)
    })
  })

  describe('Post Grade Feature', () => {
    async function subject(specific_properties: any) {
      render(<ActionMenu {...specific_properties} />)
      const actionButton = screen.getByText('Actions')
      await userEvent.click(actionButton)
    }

    test('launches the PostGrades App when selected', async function () {
      const spy = jest.spyOn(PostGradesApp, 'AppLaunch').mockImplementation(() => {})
      props.postGradesFeature.enabled = true
      await subject(props)

      const syncButton = screen.getByTestId('post_grades_feature_tool')
      await userEvent.click(syncButton)

      await waitFor(() => {
        expect(spy).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('Publish grades to SIS', () => {
    async function subject(specific_properties: any) {
      render(<ActionMenu {...specific_properties} />)
      const actionButton = screen.getByText('Actions')
      await userEvent.click(actionButton)
    }

    test('Calls gotoUrl with publishToSisUrl when clicked', async function () {
      props.publishGradesToSis = {
        isEnabled: true,
        publishToSisUrl: 'http://example.com',
      }
      await subject(props)
      const spy = jest.spyOn(ActionMenu, 'gotoUrl')
      await userEvent.click(screen.getByText('Sync grades to SIS'))
      expect(spy).toHaveBeenCalledWith('http://example.com')
    })

    test('Does not render menu item when isEnabled is false and publishToSisUrl is undefined', async () => {
      props.publishGradesToSis = {isEnabled: false}
      await subject(props)
      expect(screen.queryByText('Sync grades to SIS')).not.toBeInTheDocument()
    })

    test('Does not render menu item when isEnabled is true and publishToSisUrl is undefined', async () => {
      props.publishGradesToSis = {isEnabled: true}
      await subject(props)
      expect(screen.queryByText('Sync grades to SIS')).not.toBeInTheDocument()
    })
  })
})
