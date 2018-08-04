/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import 'compiled/jquery/ModuleSequenceFooter'

const default_course_url =
  '/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123&frame_external_urls=true'

const server_200_response = data => [
  200,
  {'Content-Type': 'application/json'},
  JSON.stringify(data)
]

const nextButton = el => el.find('.module-sequence-footer-button--next').last()

const moduleData = (args = {}) => ({
  items: [
    {
      current: {id: 768, module_id: 123, title: 'A lonely page', type: 'Page'},
      next: {id: 111, module_id: 123, title: 'Project 33', type: 'Assignment'},
      mastery_path: args.mastery_path
    }
  ],
  modules: [{id: 123, name: 'Module A'}],
  ...args
})

const basePathData = (args = {}) => ({
  is_student: true,
  choose_url: 'chew-z',
  modules_url: 'mod.module.mod',
  ...args
})

QUnit.module('ModuleSequenceFooter: init', {
  setup() {
    this.$testEl = $('<div>')
    $('#fixtures').append(this.$testEl)
    sandbox.stub($.fn.moduleSequenceFooter.MSFClass.prototype, 'fetch').returns({done() {}})
  },

  teardown() {
    this.$testEl.remove()
  }
})

test('returns jquery object of itself', function() {
  const jobj = this.$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
  ok(jobj instanceof $, 'returns an jquery instance of itself')
})

test('throws error if option is not set', () =>
  throws(function() {
    this.$testEl.moduleSequenceFooter()
  }, 'throws error when no options are passed in'))

test('generatess a url based on the course_id', function() {
  const msf = new $.fn.moduleSequenceFooter.MSFClass({
    courseID: 42,
    assetType: 'Assignment',
    assetID: 42
  })
  equal(msf.url, '/api/v1/courses/42/module_item_sequence', 'generates a url based on the courseID')
})

test('attaches msfAnimation function', function() {
  this.$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
  notStrictEqual(this.$testEl.msfAnimation, undefined, 'msfAnimation function defined')
})

test('accepts animation option', function() {
  $.fn.moduleSequenceFooter.MSFClass.prototype.fetch.restore()
  sandbox.stub($.fn.moduleSequenceFooter.MSFClass.prototype, 'fetch').callsFake(function() {
    this.success({
      items: [
        {
          prev: null,
          current: {
            id: 42,
            module_id: 73,
            title: 'A lonely page',
            type: 'Page'
          },
          next: {
            id: 43,
            module_id: 73,
            title: 'Another lonely page',
            type: 'Page'
          }
        }
      ],
      modules: [
        {
          id: 73,
          name: 'A lonely module'
        }
      ]
    })
    const d = $.Deferred()
    d.resolve()
    return d
  })
  this.$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42, animation: false})
  equal(
    this.$testEl.find('.module-sequence-footer.no-animation').length,
    1,
    'no-animation applied to module-sequence-footer'
  )
  equal(
    this.$testEl.find('.module-sequence-padding.no-animation').length,
    1,
    'no-animation applied to module-sequence-padding'
  )

  this.$testEl.msfAnimation(true)
  equal(
    this.$testEl.find('.module-sequence-footer:not(.no-animation)').length,
    1,
    'no-animation removed from module-sequence-footer'
  )
  equal(
    this.$testEl.find('.module-sequence-padding:not(.no-animation)').length,
    1,
    'no-animation removed from module-sequence-padding'
  )
})

QUnit.module('ModuleSequenceFooter: rendering', {
  setup() {
    this.server = sinon.fakeServer.create()
    this.$testEl = $('<div>')
    $('#fixtures').append(this.$testEl)
  },
  teardown() {
    this.server.restore()
    this.$testEl.remove()
  }
})

const nullButtonData = (args = {}) => ({
  items: [
    {
      prev: null,
      current: {
        id: 768,
        module_id: 123,
        title: 'A lonely page',
        type: 'Page'
      },
      next: null,
      mastery_path: args.mastery_path
    }
  ],
  modules: [
    {
      id: 123,
      name: 'Module A'
    }
  ],
  ...args
})

test('there is no button when next or prev data is null', function() {
  this.server.respondWith('GET', default_course_url, server_200_response(nullButtonData()))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(this.$testEl.find('a').length === 0, 'no buttons rendered')
})

const moduleTooltipData = {
  items: [
    {
      prev: {
        id: 769,
        module_id: 111,
        title: 'Project 1',
        type: 'Assignment'
      },
      current: {
        id: 768,
        module_id: 123,
        title: 'A lonely page',
        type: 'Page'
      },
      next: {
        id: 111,
        module_id: 666,
        title: 'Project 33',
        type: 'Assignment'
      }
    }
  ],

  modules: [
    {
      id: 123,
      name: 'Module A'
    },
    {
      id: 666,
      name: 'Module B'
    },
    {
      id: 111,
      name: 'Module C'
    }
  ]
}
test('buttons show modules tooltip when current module id != next or prev module id', function() {
  this.server.respondWith('GET', default_course_url, server_200_response(moduleTooltipData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    this.$testEl
      .find('a')
      .first()
      .data('html-tooltip-title')
      .match('Module C'),
    'displays previous module tooltip'
  )
  ok(
    nextButton(this.$testEl)
      .data('html-tooltip-title')
      .match('Module B'),
    'displays next module tooltip'
  )
})

const itemTooltipData = {
  items: [
    {
      prev: {
        id: 769,
        module_id: 123,
        title: 'Project 1',
        type: 'Assignment'
      },
      current: {
        id: 768,
        module_id: 123,
        title: 'A lonely page',
        type: 'Page'
      },
      next: {
        id: 111,
        module_id: 123,
        title: 'Project 33',
        type: 'Assignment'
      }
    }
  ],

  modules: [
    {
      id: 123,
      name: 'Module A'
    }
  ]
}

test('buttons show item tooltip when current module id == next or prev module id', function() {
  this.server.respondWith('GET', default_course_url, server_200_response(itemTooltipData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    this.$testEl
      .find('a')
      .first()
      .data('html-tooltip-title')
      .match('Project 1'),
    'displays previous item tooltip'
  )
  ok(
    nextButton(this.$testEl)
      .data('html-tooltip-title')
      .match('Project 33'),
    'displays next item tooltip'
  )
})

test('if url has a module_item_id use that as the assetID and ModuleItem as the type instead', function() {
  this.server.respondWith(
    'GET',
    '/api/v1/courses/42/module_item_sequence?asset_type=ModuleItem&asset_id=999&frame_external_urls=true',
    server_200_response({})
  )

  this.$testEl.moduleSequenceFooter({
    courseID: 42,
    assetType: 'Assignment',
    assetID: 123,
    location: {search: '?module_item_id=999'}
  })
  this.server.respond()
  equal(this.server.requests[0].status, '200', 'Request was successful')
})

test('show gets called when rendering', function() {
  sandbox.stub(this.$testEl, 'show')
  this.server.respondWith('GET', default_course_url, server_200_response(itemTooltipData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(this.$testEl.show.called, 'show called')
})

test('resize event gets triggered', function(assert) {
  const done = assert.async()
  $(window).resize(() => {
    ok(true, 'resize event triggered')
    $(window).off('resize')
    done()
  })
  this.server.respondWith('GET', default_course_url, server_200_response(itemTooltipData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
})

test('provides correct tooltip for mastery path when awaiting choice', function() {
  const pathData = moduleData({mastery_path: basePathData({awaiting_choice: true})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Choose the next mastery path'),
    'indicates a user needs to choose the next mastery path'
  )
  ok(
    btn
      .find('a')
      .attr('href')
      .match('chew-z'),
    'displays the correct link'
  )
})

test('provides correct tooltip for mastery path when awaiting choice and not a student', function() {
  const pathData = moduleData({
    mastery_path: basePathData({awaiting_choice: true, is_student: false})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Project 33'),
    'ignores awaiting_choice and displays next module item'
  )
})

test('provides correct tooltip for mastery path when sequence is locked', function() {
  const pathData = moduleData({mastery_path: basePathData({locked: true})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Next mastery path is currently locked'),
    'indicates there are locked mastery path items'
  )
  ok(
    btn
      .find('a')
      .attr('href')
      .match('mod.module.mod'),
    'displays the correct link'
  )
})

test('provides correct tooltip for mastery path when sequence is locked and not a student', function() {
  const pathData = moduleData({mastery_path: basePathData({locked: true, is_student: false})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Project 33'),
    'ignores locked status and displays next module item'
  )
})

test('provides correct tooltip for mastery path when processing', function() {
  const pathData = moduleData({mastery_path: basePathData({still_processing: true})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Next mastery path is still processing'),
    'indicates path is processing'
  )
  ok(
    btn
      .find('a')
      .attr('href')
      .match('mod.module.mod'),
    'displays the correct link'
  )
})

test('provides correct tooltip for mastery path when path is processing and not a student', function() {
  const pathData = moduleData({
    mastery_path: basePathData({still_processing: true, is_student: false})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Project 33'),
    'ignores processing state and displays next module item'
  )
})

test('properly disables the next button when path locked and modules tab disabled', function() {
  const pathData = moduleData({
    mastery_path: basePathData({locked: true, modules_tab_disabled: true})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    nextButton(this.$testEl)
      .find('a')
      .attr('disabled'),
    'disables the button'
  )
})

test('does not disable the next button when path locked and modules tab disabled and not a student', function() {
  const pathData = moduleData({
    mastery_path: basePathData({locked: true, modules_tab_disabled: true, is_student: false})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    !nextButton(this.$testEl)
      .find('a')
      .attr('disabled'),
    'does not disable the button'
  )
})

test('properly disables the next button when path processing and modules tab disabled', function() {
  const pathData = moduleData({
    mastery_path: basePathData({still_processing: true, modules_tab_disabled: true})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    nextButton(this.$testEl)
      .find('a')
      .attr('disabled'),
    'disables the button'
  )
})

test('does not disable the next button when path processing and modules tab disabled and not a student', function() {
  const pathData = moduleData({
    mastery_path: basePathData({
      still_processing: true,
      modules_tab_disabled: true,
      is_student: false
    })
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    !nextButton(this.$testEl)
      .find('a')
      .attr('disabled'),
    'does not disable the button'
  )
})

test('does not disable the next button when awaiting choice and modules tab disabled', function() {
  const pathData = moduleData({
    mastery_path: basePathData({awaiting_choice: true, modules_tab_disabled: true})
  })
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(
    !nextButton(this.$testEl)
      .find('a')
      .attr('disabled'),
    'does not disable the button'
  )
})

test('properly shows next button when no next items yet exist and paths are locked', function() {
  const pathData = nullButtonData({mastery_path: basePathData({locked: true})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Next mastery path is currently locked'),
    'indicates there are locked mastery path items'
  )
  ok(
    btn
      .find('a')
      .attr('href')
      .match('mod.module.mod'),
    'displays the correct link'
  )
})

test('properly shows next button when no next items yet exist and paths are processing', function() {
  const pathData = nullButtonData({mastery_path: basePathData({still_processing: true})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()
  const btn = nextButton(this.$testEl)

  ok(
    btn.data('html-tooltip-title').match('Next mastery path is still processing'),
    'indicates path is processing'
  )
  ok(
    btn
      .find('a')
      .attr('href')
      .match('mod.module.mod'),
    'displays the correct link'
  )
})

test('does not show next button when no next items exist and paths are unlocked', function() {
  const pathData = nullButtonData({mastery_path: basePathData({still_processing: false})})
  this.server.respondWith('GET', default_course_url, server_200_response(pathData))
  this.$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
  this.server.respond()

  ok(this.$testEl.find('a').length === 0, 'no buttons rendered')
})
