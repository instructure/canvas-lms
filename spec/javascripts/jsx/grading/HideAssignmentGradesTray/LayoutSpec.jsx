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
import ReactDOM from 'react-dom'

import Layout from '@canvas/hide-assignment-grades-tray/react/Layout'

QUnit.module('HideAssignmentGradesTray Layout', suiteHooks => {
  let $container

  function getHeader() {
    return [...$container.querySelectorAll('h3')].find($header =>
      $header.textContent.includes('Hide Grades')
    )
  }

  function getAnonymousText() {
    const hideText =
      'When hiding grades for anonymous assignments, grades will be hidden for everyone in the course. Anonymity will be re-applied.'
    return [...$container.querySelectorAll('div')].find($el => $el.textContent === hideText)
  }

  function getRefreshText() {
    const refreshText = 'Hiding grades will refresh your browser. This may take a moment.'
    return [...$container.querySelectorAll('div')].find($el => $el.textContent === refreshText)
  }

  function getUnreleasedGradesAlertText() {
    const hideText =
      'Hiding grades is not allowed because grades have not been released for this assignment.'
    return [...$container.querySelectorAll('div')].find($p => $p.textContent === hideText)
  }

  function layoutProps({assignment, ...props} = {}) {
    return {
      assignment: {
        anonymousGrading: false,
        gradesPublished: true,
        ...assignment,
      },
      dismiss() {},
      hideBySections: true,
      hideBySectionsChanged() {},
      hidingGrades: false,
      onHideClick() {},
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
      sectionSelectionChanged() {},
      selectedSectionIds: [],
      ...props,
    }
  }

  function mountComponent(props = {}) {
    ReactDOM.render(<Layout {...layoutProps(props)} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('header is present', () => {
    mountComponent()
    ok(getHeader())
  })

  QUnit.module('"Unreleased grades" message behavior', () => {
    test('when "gradesPublished" is false, unreleased grades message is present', () => {
      mountComponent({assignment: {gradesPublished: false}})
      ok(getUnreleasedGradesAlertText())
    })

    test('when "gradesPublished" is true, unreleased grades message is hidden', () => {
      mountComponent({assignment: {gradesPublished: true}})
      notOk(getUnreleasedGradesAlertText())
    })
  })

  QUnit.module('"will refresh your browser" text behavior', contextHooks => {
    let assignment
    let containerName

    contextHooks.beforeEach(() => {
      assignment = {anonymousGrading: true, gradesPublished: true}
      containerName = 'SPEED_GRADER'
    })

    test('when gradesPublished and anonymousGrading are true, and containerName is SPEED_GRADER, refresh text is present', () => {
      mountComponent({assignment, containerName})
      ok(getRefreshText())
    })

    test('when gradesPublished is false, refresh text is not present', () => {
      assignment.gradesPublished = false
      mountComponent({assignment, containerName})
      notOk(getRefreshText())
    })

    test('when anonymousGrading is false, refresh text is not present', () => {
      assignment.anonymousGrading = false
      mountComponent({assignment, containerName})
      notOk(getRefreshText())
    })

    test('when containerName is not SPEED_GRADER, refresh text is not present', () => {
      containerName = 'NOT_SPEED_GRADER'
      mountComponent({assignment, containerName})
      notOk(getRefreshText())
    })
  })

  QUnit.module('"for everyone when assignment is anonymous" text behavior', contextHooks => {
    let assignment
    let sections

    contextHooks.beforeEach(() => {
      assignment = {
        gradesPublished: true,
        anonymousGrading: true,
      }
      sections = [{id: '2001', name: 'Freshmen'}]
    })

    test('when "gradesPublished" and "anonymousGrading" are true and at least one section, anonymous descriptive text is present', () => {
      mountComponent({assignment, sections})
      ok(getAnonymousText())
    })

    test('when "gradesPublished" is false, anonymous descriptive text is hidden', () => {
      assignment.gradesPublished = false
      mountComponent({assignment, sections})
      notOk(getAnonymousText())
    })

    test('when "sections" are empty, anonymous descriptive text is hidden', () => {
      sections = []
      mountComponent({assignment, sections})
      notOk(getAnonymousText())
    })

    test('when "anonymousGrading" is false, anonymous descriptive text is hidden', () => {
      assignment.anonymousGrading = false
      mountComponent({assignment, sections})
      notOk(getAnonymousText())
    })
  })
})
