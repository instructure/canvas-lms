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

import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageCollection from '../../collections/WikiPageCollection'
import WikiPageIndexView from '../WikiPageIndexView'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.disableWhileLoading'
import fakeENV from '@canvas/test-utils/fakeENV'
import * as ConfirmDeleteModal from '../../../react/ConfirmDeleteModal'

jest.mock('../../../react/ConfirmDeleteModal', () => ({
  showConfirmDelete: jest.fn(),
}))

const indexMenuLtiTool = {
  id: '18',
  title: 'Named LTI Tool',
  base_url: 'http://localhost/courses/1/external_tools/18?launch_type=wiki_index_menu',
  tool_id: 'named_lti_tool',
  icon_url: 'http://localhost:3001/icon.png',
  canvas_icon_class: null,
}

describe('WikiPageIndexView', () => {
  let prevHtml

  describe('confirmDeletePages not checked', () => {
    let view
    let collection
    let model

    beforeEach(() => {
      prevHtml = document.body.innerHTML
      fakeENV.setup({
        context_asset_string: 'course_1',
      })
      model = new WikiPage({page_id: '42'})
      collection = new WikiPageCollection([model])
      view = new WikiPageIndexView({
        collection,
      })
    })

    afterEach(() => {
      document.body.innerHTML = prevHtml
      fakeENV.teardown()
      jest.clearAllMocks()
    })

    it('does not call showConfirmDelete when no pages are checked', () => {
      view.confirmDeletePages(null)
      expect(ConfirmDeleteModal.showConfirmDelete).not.toHaveBeenCalled()
    })
  })

  describe('confirmDeletePages checked', () => {
    let view
    let collection
    let model

    beforeEach(() => {
      prevHtml = document.body.innerHTML
      fakeENV.setup({
        context_asset_string: 'course_1',
      })
      model = new WikiPage({page_id: '42', title: 'page 42'})
      collection = new WikiPageCollection([model])
      view = new WikiPageIndexView({
        collection,
        selectedPages: {42: model},
      })
    })

    afterEach(() => {
      document.body.innerHTML = prevHtml
      fakeENV.teardown()
      jest.clearAllMocks()
    })

    it('calls showConfirmDelete when pages are checked', () => {
      view.confirmDeletePages(null)
      expect(ConfirmDeleteModal.showConfirmDelete).toHaveBeenCalledWith(
        expect.objectContaining({
          pageTitles: ['page 42'],
        }),
      )
    })
  })

  describe('direct_share', () => {
    let view
    let collection
    let model

    beforeEach(() => {
      fakeENV.setup({
        DIRECT_SHARE_ENABLED: true,
        COURSE_ID: 'a course',
        context_asset_string: 'course_1',
      })
      model = new WikiPage({page_id: '42'})
      collection = new WikiPageCollection([model])
      view = new WikiPageIndexView({
        collection,
        WIKI_RIGHTS: {
          create_page: true,
          manage: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      jest.clearAllMocks()
    })

    it('opens and closes the direct share course tray', () => {
      const trayComponent = jest.spyOn(view, 'DirectShareCourseTray').mockReturnValue(null)
      collection.trigger('fetch')
      view.$el.find('.copy-wiki-page-to').click()
      expect(trayComponent).toHaveBeenCalledWith(
        expect.objectContaining({
          open: true,
          sourceCourseId: 'a course',
          contentSelection: {pages: ['42']},
        }),
        {},
      )
      trayComponent.mock.calls[0][0].onDismiss()
      expect(trayComponent).toHaveBeenLastCalledWith(
        expect.objectContaining({
          open: false,
        }),
        {},
      )
    })

    it('opens and closes the direct share user modal', () => {
      const userModal = jest.spyOn(view, 'DirectShareUserModal').mockReturnValue(null)
      collection.trigger('fetch')
      view.$el.find('.send-wiki-page-to').click()
      expect(userModal).toHaveBeenCalledWith(
        expect.objectContaining({
          open: true,
          courseId: 'a course',
          contentShare: {
            content_id: '42',
            content_type: 'page',
          },
        }),
        {},
      )
      userModal.mock.calls[0][0].onDismiss()
      expect(userModal).toHaveBeenLastCalledWith(
        expect.objectContaining({
          open: false,
        }),
        {},
      )
    })
  })

  describe('open_external_tool', () => {
    let view
    let collection
    let model

    beforeEach(() => {
      fakeENV.setup({
        COURSE_ID: 'a course',
        context_asset_string: 'course_1',
      })
      model = new WikiPage({page_id: '42'})
      collection = new WikiPageCollection([model])
      view = new WikiPageIndexView({
        collection,
        WIKI_RIGHTS: {
          create_page: true,
          manage: true,
        },
        wikiIndexPlacements: indexMenuLtiTool,
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      delete window.ltiTrayState
      jest.clearAllMocks()
    })

    it('opens and closes the lti tray and returns focus', () => {
      const trayComponent = jest.spyOn(view, 'ContentTypeExternalToolTray').mockReturnValue(null)
      collection.trigger('fetch')
      const toolbarKabobMenu = view.$el.find('.al-trigger')[0]
      view.setExternalToolTray(indexMenuLtiTool, toolbarKabobMenu)
      expect(trayComponent).toHaveBeenCalledWith(
        expect.objectContaining({
          tool: indexMenuLtiTool,
          placement: 'wiki_index_menu',
          acceptedResourceTypes: ['page'],
          targetResourceType: 'page',
          allowItemSelection: false,
          selectableItems: [],
          open: true,
        }),
        {},
      )
      trayComponent.mock.calls[0][0].onDismiss()
      expect(trayComponent).toHaveBeenLastCalledWith(
        expect.objectContaining({
          open: false,
        }),
        {},
      )
    })

    it('reloads page when closing tray if needed', () => {
      const trayComponent = jest.spyOn(view, 'ContentTypeExternalToolTray').mockReturnValue(null)
      collection.trigger('fetch')
      const toolbarKabobMenu = view.$el.find('.al-trigger')[0]
      view.setExternalToolTray(indexMenuLtiTool, toolbarKabobMenu)
      expect(trayComponent).toHaveBeenCalledWith(
        expect.objectContaining({
          tool: indexMenuLtiTool,
          placement: 'wiki_index_menu',
          acceptedResourceTypes: ['page'],
          targetResourceType: 'page',
          allowItemSelection: false,
          selectableItems: [],
          open: true,
        }),
        {},
      )
    })
  })

  describe('sorting', () => {
    let view
    let collection
    let model

    beforeEach(() => {
      fakeENV.setup({
        context_asset_string: 'course_1',
      })
      model = new WikiPage({page_id: '42'})
      collection = new WikiPageCollection([model])
      view = new WikiPageIndexView({
        collection,
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      jest.clearAllMocks()
    })

    it('delegates to the collection sortByField', () => {
      const sortByFieldStub = jest.spyOn(collection, 'sortByField')
      const mockEvent = {
        preventDefault: jest.fn(),
        currentTarget: $('<div>').data('sort-field', 'title')[0],
      }
      view.sort(mockEvent)
      expect(sortByFieldStub).toHaveBeenCalled()
    })
  })
})
