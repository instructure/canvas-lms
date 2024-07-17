/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import LearningMastery from '../LearningMastery'
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import ContentFilterDriver from '@canvas/grading/content-filters/ContentFilterDriver'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
  destroyContainer: jest.fn(),
}))

describe('Learning Mastery > LearningMastery', () => {
  let container
  let learningMastery
  let options

  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        context_id: '1201',
        context_url: '/courses/1201',
        outcome_proficiency: null,
        settings_update_url: '/courses/1201/gradebook_settings',
      },
    })

    container = document.createElement('div')
    container.innerHTML = `
      <div id="wrapper" class="ic-Layout-wrapper">
        <div id="main" class="ic-Layout-columns">
          <div id="not_right_side" class="ic-app-main-content">
            <div class="outcome-gradebook-container">
              <div class="outcome-menus">
                <span data-component="SectionFilter"></span>
                <span data-component="GradebookMenu"></span>
              </div>

              <div class="outcome-gradebook"></div>
              <div id="outcome-gradebook-paginator"></div>
            </div>
          </div>
        </div>
      </div>
    `
    document.body.appendChild(container)

    options = {
      ...ENV.GRADEBOOK_OPTIONS,
      sections: [],
      settings: {
        filter_rows_by: {
          section_id: null,
        },
      },
    }
  })

  afterEach(() => {
    if (learningMastery) {
      learningMastery.destroy()
    }
    container.remove()
    fakeENV.teardown()
  })

  describe('sections', () => {
    beforeEach(() => {
      options.sections = [
        {id: '2003', name: 'Juniors'},
        {id: '2001', name: 'Sophomores'},
        {id: '2002', name: 'Freshmen'},
      ]
      learningMastery = new LearningMastery(options)
    })

    it('returns the sections from the options', () => {
      expect(learningMastery.getSections().length).toBe(3)
    })

    it('sorts sections by id', () => {
      const sections = learningMastery.getSections()
      expect(sections.map(section => section.id)).toEqual(['2001', '2002', '2003'])
    })
  })

  describe('#getCurrentSectionId()', () => {
    it('returns the current section id from the options', () => {
      options.settings.filter_rows_by.section_id = '2002'
      learningMastery = new LearningMastery(options)
      expect(learningMastery.getCurrentSectionId()).toBe('2002')
    })

    it('returns null when the settings have no row filter for section id', () => {
      options.settings.filter_rows_by = {}
      learningMastery = new LearningMastery(options)
      expect(learningMastery.getCurrentSectionId()).toBeNull()
    })

    it('returns null when the settings have no row filters', () => {
      options.settings = {}
      learningMastery = new LearningMastery(options)
      expect(learningMastery.getCurrentSectionId()).toBeNull()
    })

    it('returns null when the settings do not exist', () => {
      options.settings = null
      learningMastery = new LearningMastery(options)
      expect(learningMastery.getCurrentSectionId()).toBeNull()
    })
  })

  describe('#updateCurrentSectionId()', () => {
    beforeEach(() => {
      learningMastery = new LearningMastery(options)
      jest.spyOn(learningMastery, 'saveSettings')
    })

    describe('when given a section id', () => {
      describe('when the current section id is null', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        it('saves settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          expect(learningMastery.saveSettings).toHaveBeenCalledTimes(1)
        })
      })

      describe('when the current section id is a different section id', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        it('sets the current section id to the given id', () => {
          learningMastery.updateCurrentSectionId('2001')
          expect(learningMastery.getCurrentSectionId()).toBe('2001')
        })

        it('saves settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          expect(learningMastery.saveSettings).toHaveBeenCalledTimes(1)
        })
      })

      describe('when the current section id is the same section id', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId('2001')
        })

        it('retains the current section id', () => {
          learningMastery.updateCurrentSectionId('2001')
          expect(learningMastery.getCurrentSectionId()).toBe('2001')
        })

        it('does not save settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          expect(learningMastery.saveSettings).not.toHaveBeenCalled()
        })
      })
    })

    describe('when given null (All Sections)', () => {
      describe('when the current section id is a different section id', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        it('sets the current section id to null', () => {
          learningMastery.updateCurrentSectionId(null)
          expect(learningMastery.getCurrentSectionId()).toBeNull()
        })

        it('saves settings', () => {
          learningMastery.updateCurrentSectionId(null)
          expect(learningMastery.saveSettings).toHaveBeenCalledTimes(1)
        })
      })

      describe('when the current section id is already null', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        it('retains the current section id as null', () => {
          learningMastery.updateCurrentSectionId(null)
          expect(learningMastery.getCurrentSectionId()).toBeNull()
        })

        it('does not save settings', () => {
          learningMastery.updateCurrentSectionId(null)
          expect(learningMastery.saveSettings).not.toHaveBeenCalled()
        })
      })
    })

    describe('when given "0" (All Sections)', () => {
      describe('when the current section id is a different section id', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        it('sets the current section id to null', () => {
          learningMastery.updateCurrentSectionId('0')
          expect(learningMastery.getCurrentSectionId()).toBeNull()
        })

        it('saves settings', () => {
          learningMastery.updateCurrentSectionId('0')
          expect(learningMastery.saveSettings).toHaveBeenCalledTimes(1)
        })
      })

      describe('when the current section id is already null', () => {
        beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        it('retains the current section id as null', () => {
          learningMastery.updateCurrentSectionId('0')
          expect(learningMastery.getCurrentSectionId()).toBeNull()
        })

        it('does not save settings', () => {
          learningMastery.updateCurrentSectionId('0')
          expect(learningMastery.saveSettings).not.toHaveBeenCalled()
        })
      })
    })
  })

  describe('#saveSettings()', () => {
    let server

    beforeEach(() => {
      server = new FakeServer()
      server.for(ENV.GRADEBOOK_OPTIONS.settings_update_url).respond({status: 200, body: {}})

      options.settings.filter_rows_by.section_id = '2002'
      learningMastery = new LearningMastery(options)
      learningMastery.saveSettings()
    })

    afterEach(() => {
      server.teardown()
    })

    it('sends a request to the settings update url', () => {
      const request = server.receivedRequests[0]
      expect(request.url).toBe(options.settings_update_url)
    })

    it('sends a POST request', () => {
      const request = server.receivedRequests[0]
      expect(request.method).toBe('POST')
    })

    it('includes a `_method` of PUT in the form data', () => {
      const request = server.receivedRequests[0]
      const formData = new URLSearchParams(request.requestBody)
      expect(formData.get('_method')).toBe('PUT')
    })

    it('includes the current section id', () => {
      const request = server.receivedRequests[0]
      const formData = new URLSearchParams(request.requestBody)
      const gradebookSettings = formData.get('gradebook_settings[filter_rows_by][section_id]')

      expect(gradebookSettings).toBe('2002')
    })
  })

  describe('#start()', () => {
    it('renders the outcome gradebook view', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      expect(container.querySelector('.outcome-gradebook-sidebar')).toBeTruthy()
    })

    describe('when multiple sections exist', () => {
      beforeEach(() => {
        options.sections = [
          {id: '2002', name: 'Section 2'},
          {id: '2001', name: 'Section 1'},
        ]
      })

      it('renders the section filter', () => {
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        expect(ContentFilterDriver.findWithLabelText('Section Filter', container)).toBeTruthy()
      })

      it('selects the current section in the section filter', () => {
        options.settings.filter_rows_by.section_id = '2002'
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
        expect(filter.selectedItemLabel).toBe('Section 2')
      })
    })

    describe('when only the default section exists', () => {
      it('does not render the section filter', () => {
        options.sections = [{id: '2001', name: 'Default Section'}]
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        expect(ContentFilterDriver.findWithLabelText('Section Filter', container)).toBeFalsy()
      })
    })

    it('renders the gradebook menu', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      const menuContainer = container.querySelector('[data-component="GradebookMenu"]')
      expect(menuContainer.children.length).toBeGreaterThan(0)
    })

    it('renders the outcome gradebook paginator', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      const paginatorContainer = container.querySelector('#outcome-gradebook-paginator')
      expect(paginatorContainer.children.length).toBeGreaterThan(0)
    })
  })

  describe('#destroy()', () => {
    beforeEach(() => {
      options.sections = [
        {id: '2002', name: 'Section 2'},
        {id: '2001', name: 'Section 1'},
      ]
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      learningMastery.destroy()
    })

    it('removes the outcome gradebook view', () => {
      expect(container.querySelector('.outcome-gradebook-sidebar')).toBeFalsy()
    })

    it('unmounts the section filter', () => {
      expect(ContentFilterDriver.findWithLabelText('Section Filter', container)).toBeFalsy()
    })

    it('unmounts the gradebook menu', () => {
      const menuContainer = container.querySelector('[data-component="GradebookMenu"]')
      expect(menuContainer.children.length).toBe(0)
    })

    it('unmounts the outcome gradebook paginator', () => {
      const paginatorContainer = container.querySelector('#outcome-gradebook-paginator')
      expect(paginatorContainer.children.length).toBe(0)
    })
  })
})
