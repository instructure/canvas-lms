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

import fakeENV from 'helpers/fakeENV'
import LearningMastery from 'ui/features/learning_mastery/react/LearningMastery'
import FakeServer, {
  formBodyFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import ContentFilterDriver from '../gradebook/default_gradebook/components/content-filters/ContentFilterDriver'

QUnit.module('Learning Mastery > LearningMastery', suiteHooks => {
  let $container
  let learningMastery
  let options

  suiteHooks.beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        context_id: '1201',
        context_url: '/courses/1201',
        outcome_proficiency: null,
        settings_update_url: '/courses/1201/gradebook_settings',
      },
    })

    $container = document.createElement('div')
    $container.innerHTML = `
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
    document.body.appendChild($container)

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

  suiteHooks.afterEach(() => {
    learningMastery.destroy()
    $container.remove()
    fakeENV.teardown()
  })

  QUnit.module('sections', hooks => {
    hooks.beforeEach(() => {
      options.sections = [
        {id: '2003', name: 'Juniors'},
        {id: '2001', name: 'Sophomores'},
        {id: '2002', name: 'Freshmen'},
      ]
      learningMastery = new LearningMastery(options)
    })

    test('#getSections() returns the sections from the options', () => {
      strictEqual(learningMastery.getSections().length, 3)
    })

    test('sorts sections by id', () => {
      const sections = learningMastery.getSections()
      deepEqual(
        sections.map(section => section.id),
        ['2001', '2002', '2003']
      )
    })
  })

  QUnit.module('#getCurrentSectionId()', () => {
    test('returns the current section id from the options', () => {
      options.settings.filter_rows_by.section_id = '2002'
      learningMastery = new LearningMastery(options)
      strictEqual(learningMastery.getCurrentSectionId(), '2002')
    })

    test('returns null when the settings have no row filter for section id', () => {
      options.settings.filter_rows_by = {}
      learningMastery = new LearningMastery(options)
      strictEqual(learningMastery.getCurrentSectionId(), null)
    })

    test('returns null when the settings have no row filters', () => {
      options.settings = {}
      learningMastery = new LearningMastery(options)
      strictEqual(learningMastery.getCurrentSectionId(), null)
    })

    test('returns null when the settings do not exist', () => {
      options.settings = null
      learningMastery = new LearningMastery(options)
      strictEqual(learningMastery.getCurrentSectionId(), null)
    })
  })

  QUnit.module('#updateCurrentSectionId()', hooks => {
    hooks.beforeEach(() => {
      learningMastery = new LearningMastery(options)
      sandbox.stub(learningMastery, 'saveSettings')
    })

    QUnit.module('when given a section id', () => {
      QUnit.module('when the current section id is null', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        test('saves settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.saveSettings.callCount, 1)
        })
      })

      QUnit.module('when the current section id is a different section id', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        test('sets the current section id to the given id', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.getCurrentSectionId(), '2001')
        })

        test('saves settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.saveSettings.callCount, 1)
        })
      })

      QUnit.module('when the current section id is the same section id', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId('2001')
        })

        test('retains the current section id', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.getCurrentSectionId(), '2001')
        })

        test('does not save settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.saveSettings.callCount, 0)
        })
      })
    })

    QUnit.module('when given null (All Sections)', () => {
      QUnit.module('when the current section id is a different section id (2)', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        test('sets the current section id to the given id', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.getCurrentSectionId(), '2001')
        })

        test('saves settings', () => {
          learningMastery.updateCurrentSectionId('2001')
          strictEqual(learningMastery.saveSettings.callCount, 1)
        })
      })

      QUnit.module('when the current section id is null (2)', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        test('retains the current section id', () => {
          learningMastery.updateCurrentSectionId(null)
          strictEqual(learningMastery.getCurrentSectionId(), null)
        })

        test('does not save settings', () => {
          learningMastery.updateCurrentSectionId(null)
          strictEqual(learningMastery.saveSettings.callCount, 0)
        })
      })
    })

    QUnit.module('when given "0" (All Sections)', () => {
      QUnit.module('when the current section id is a different section id (3)', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId('2002')
        })

        test('sets the current section id to the given id', () => {
          learningMastery.updateCurrentSectionId('0')
          strictEqual(learningMastery.getCurrentSectionId(), null)
        })

        test('saves settings', () => {
          learningMastery.updateCurrentSectionId('0')
          strictEqual(learningMastery.saveSettings.callCount, 1)
        })
      })

      QUnit.module('when the current section id is null (3)', contextHooks => {
        contextHooks.beforeEach(() => {
          learningMastery._setCurrentSectionId(null)
        })

        test('retains the current section id', () => {
          learningMastery.updateCurrentSectionId(null)
          strictEqual(learningMastery.getCurrentSectionId(), null)
        })

        test('does not save settings', () => {
          learningMastery.updateCurrentSectionId(null)
          strictEqual(learningMastery.saveSettings.callCount, 0)
        })
      })
    })
  })

  QUnit.module('#saveSettings()', hooks => {
    let server

    hooks.beforeEach(() => {
      server = new FakeServer()
      server.for(ENV.GRADEBOOK_OPTIONS.settings_update_url).respond({status: 200, body: {}})

      options.settings.filter_rows_by.section_id = '2002'
      learningMastery = new LearningMastery(options)
      learningMastery.saveSettings()
    })

    hooks.afterEach(() => {
      server.teardown()
    })

    test('sends a request to the settings update url', () => {
      const request = server.receivedRequests[0]
      equal(request.url, options.settings_update_url)
    })

    test('sends a POST request', () => {
      const request = server.receivedRequests[0]
      equal(request.method, 'POST')
    })

    test('includes a `_method` of PUT in the form data', () => {
      const request = server.receivedRequests[0]
      const formData = formBodyFromRequest(request)
      equal(formData._method, 'PUT')
    })

    test('includes the current section id', () => {
      const request = server.receivedRequests[0]
      const settings = formBodyFromRequest(request).gradebook_settings
      strictEqual(settings.filter_rows_by.section_id, '2002')
    })
  })

  QUnit.module('#start()', () => {
    test('renders the outcome gradebook view', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      ok($container.querySelector('.outcome-gradebook-sidebar'))
    })

    QUnit.module('when multiple sections exist', contextHooks => {
      contextHooks.beforeEach(() => {
        options.sections = [
          {id: '2002', name: 'Section 2'},
          {id: '2001', name: 'Section 1'},
        ]
      })

      test('renders the section filter', () => {
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        ok(ContentFilterDriver.findWithLabelText('Section Filter', $container))
      })

      test('selects the current section in the section filter', () => {
        options.settings.filter_rows_by.section_id = '2002'
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        const filter = ContentFilterDriver.findWithLabelText('Section Filter', $container)
        strictEqual(filter.selectedItemLabel, 'Section 2')
      })
    })

    QUnit.module('when only the default section exists', () => {
      test('does not render the section filter', () => {
        options.sections = [{id: '2001', name: 'Default Section'}]
        learningMastery = new LearningMastery(options)
        learningMastery.start()
        notOk(ContentFilterDriver.findWithLabelText('Section Filter', $container))
      })
    })

    test('renders the gradebook menu', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      const $menuContainer = $container.querySelector('[data-component="GradebookMenu"]')
      ok($menuContainer.children.length > 0)
    })

    test('renders the outcome gradebook paginator', () => {
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      const $paginatorContainer = $container.querySelector('#outcome-gradebook-paginator')
      ok($paginatorContainer.children.length > 0)
    })
  })

  QUnit.module('#destroy()', hooks => {
    hooks.beforeEach(() => {
      options.sections = [
        {id: '2002', name: 'Section 2'},
        {id: '2001', name: 'Section 1'},
      ]
      learningMastery = new LearningMastery(options)
      learningMastery.start()
      learningMastery.destroy()
    })

    test('removes the outcome gradebook view', () => {
      notOk($container.querySelector('.outcome-gradebook-sidebar'))
    })

    test('unmounts the section filter', () => {
      notOk(ContentFilterDriver.findWithLabelText('Section Filter', $container))
    })

    test('unmounts the gradebook menu', () => {
      const $menuContainer = $container.querySelector('[data-component="GradebookMenu"]')
      strictEqual($menuContainer.children.length, 0)
    })

    test('unmounts the outcome gradebook paginator', () => {
      const $paginatorContainer = $container.querySelector('#outcome-gradebook-paginator')
      strictEqual($paginatorContainer.children.length, 0)
    })
  })
})
