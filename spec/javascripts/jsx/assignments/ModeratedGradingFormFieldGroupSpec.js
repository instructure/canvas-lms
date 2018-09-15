/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import ModeratedGradingFormFieldGroup from 'jsx/assignments/ModeratedGradingFormFieldGroup'

QUnit.module('ModeratedGradingFormFieldGroup', hooks => {
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {
      availableModerators: [{name: 'John Doe', id: '923'}, {name: 'Jane Doe', id: '492'}],
      finalGraderID: undefined,
      graderCommentsVisibleToGraders: true,
      graderNamesVisibleToFinalGrader: true,
      gradedSubmissionsExist: false,
      isGroupAssignment: false,
      isPeerReviewAssignment: false,
      locale: 'en',
      maxGraderCount: 10,
      moderatedGradingEnabled: true,
      onGraderCommentsVisibleToGradersChange() {},
      onModeratedGradingChange() {}
    }
  })

  function mountComponent() {
    wrapper = mount(<ModeratedGradingFormFieldGroup {...props} />)
  }

  function content() {
    return wrapper.find('.ModeratedGrading__Content')
  }

  test('hides the moderated grading content when passed moderatedGradingEnabled: false', () => {
    props.moderatedGradingEnabled = false
    mountComponent()
    strictEqual(content().length, 0)
  })

  test('shows the moderated grading content when passed moderatedGradingEnabled: true', () => {
    mountComponent()
    strictEqual(content().length, 1)
  })

  test('includes a final grader select menu in the moderated grading content', () => {
    mountComponent()
    const selectMenu = content().find('select[name="final_grader_id"]')
    strictEqual(selectMenu.length, 1)
  })

  test('includes a grader count input in the moderated grading content', () => {
    mountComponent()
    const graderCountInput = content().find('input[name="grader_count"]')
    strictEqual(graderCountInput.length, 1)
  })

  QUnit.module('Moderated Grading Checkbox', () => {
    function moderatedGradingCheckbox() {
      return wrapper.find('input#assignment_moderated_grading[type="checkbox"]')
    }

    test('renders the checkbox', () => {
      mountComponent()
      strictEqual(moderatedGradingCheckbox().length, 1)
    })

    test('renders an unchecked checkbox when passed moderatedGradingEnabled: false', () => {
      props.moderatedGradingEnabled = false
      mountComponent()
      strictEqual(moderatedGradingCheckbox().node.checked, false)
    })

    test('renders a checked checkbox when passed moderatedGradingEnabled: true', () => {
      mountComponent()
      strictEqual(moderatedGradingCheckbox().node.checked, true)
    })

    test('hides the moderated grading content when the checkbox is unchecked', () => {
      mountComponent()
      moderatedGradingCheckbox().simulate('change')
      strictEqual(content().length, 0)
    })

    test('shows the moderated grading content when the checkbox is checked', () => {
      props.moderatedGradingEnabled = false
      mountComponent()
      moderatedGradingCheckbox().simulate('change')
      strictEqual(content().length, 1)
    })

    test('calls onModeratedGradingChange when the checkbox is checked', () => {
      props.moderatedGradingEnabled = false
      sinon.stub(props, 'onModeratedGradingChange')
      mountComponent()
      moderatedGradingCheckbox().simulate('change')
      strictEqual(props.onModeratedGradingChange.callCount, 1)
      props.onModeratedGradingChange.restore()
    })

    test('calls onModeratedGradingChange when the checkbox is unchecked', () => {
      sinon.stub(props, 'onModeratedGradingChange')
      mountComponent()
      moderatedGradingCheckbox().simulate('change')
      strictEqual(props.onModeratedGradingChange.callCount, 1)
      props.onModeratedGradingChange.restore()
    })
  })

  QUnit.module('Grader Comment Visibility Checkbox', () => {
    function graderCommentsVisibleToGradersCheckbox() {
      return wrapper.find('input#assignment_grader_comment_visibility')
    }

    test('renders the checkbox', () => {
      mountComponent()
      strictEqual(graderCommentsVisibleToGradersCheckbox().length, 1)
    })

    test('renders an unchecked checkbox when passed graderCommentsVisibleToGraders: false', () => {
      props.graderCommentsVisibleToGraders = false
      mountComponent()
      strictEqual(graderCommentsVisibleToGradersCheckbox().node.checked, false)
    })

    test('renders a checked checkbox when passed graderCommentsVisibleToGraders: true', () => {
      mountComponent()
      strictEqual(graderCommentsVisibleToGradersCheckbox().node.checked, true)
    })
  })

  QUnit.module('Grader Names Visible to Final Grader Checkbox', () => {
    function graderNamesVisibleToFinalGraderCheckbox() {
      return wrapper.find('input#assignment_grader_names_visible_to_final_grader')
    }

    test('renders a grader names visible to final grader checkbox in the moderated grading content', () => {
      mountComponent()
      strictEqual(graderNamesVisibleToFinalGraderCheckbox().length, 1)
    })

    test('renders an unchecked checkbox when passed graderNamesVisibleToFinalGrader: false', () => {
      props.graderNamesVisibleToFinalGrader = false
      mountComponent()
      strictEqual(graderNamesVisibleToFinalGraderCheckbox().node.checked, false)
    })

    test('renders a checked checkbox for Moderated Grading when passed graderNamesVisibleToFinalGrader: true', () => {
      mountComponent()
      strictEqual(graderNamesVisibleToFinalGraderCheckbox().node.checked, true)
    })
  })
})
