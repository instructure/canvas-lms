// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import 'jqueryui/dialog'
import 'jquery-tinypubsub'
import {FocusRegionManager} from '@instructure/ui-a11y-utils'

const I18n = createI18nScope('assignmentRubricDialog')

const assignmentRubricDialog = {
  focusRegion: null,

  initTriggers() {
    const $trigger = $('.rubric_dialog_trigger')
    if ($trigger) {
      this.noRubricExists = $trigger.data('noRubricExists')
      const selector =
        $trigger.data('focusReturnsTo') ?? '[data-testid="discussion-post-menu-trigger"]'
      try {
        this.$focusReturnsTo = $(document.querySelector(selector))
      } catch (err) {
        // no-op
      }

      $trigger.click(event => {
        event.preventDefault()
        assignmentRubricDialog.openDialog()
      })
    }
  },

  initDialog() {
    this.dialogInited = true

    this.$dialog = $(`<div><h4>${htmlEscape(I18n.t('loading', 'Loading...'))}</h4></div>`).dialog({
      title: I18n.t('titles.assignment_rubric_details', 'Assignment Rubric Details'),
      width: 600,
      modal: false,
      resizable: true,
      autoOpen: false,
      close: () => {
        const $container = this.$dialog.dialog('widget')
        this.focusRegion && FocusRegionManager.blurRegion($container[0], this.focusRegion.id)
        this.$focusReturnsTo?.focus()
      },
      open: () => {
        const $container = this.$dialog.dialog('widget')
        $container.attr('aria-modal', 'true')
        $container.find('.ui-dialog-titlebar-close').attr('tabindex', '0')
        $container.find('.add_rubric_link').attr('tabindex', '0')
        $container.find('.ui-dialog-title').attr('role', 'heading').attr('aria-level', '2')
      },
      zIndex: 1000,
    })

    return $.get(ENV.DISCUSSION.GRADED_RUBRICS_URL, html => {
      // if there is not already a rubric, we want to click the "add rubric" button for them,
      // since that is the point of why they clicked the link.
      if (assignmentRubricDialog.noRubricExists) {
        $.subscribe('edit_rubric/initted', () =>
          assignmentRubricDialog.$dialog.find('.btn.add_rubric_link').click(),
        )
      }

      // weird hackery because the server returns a <div id="rubrics" style="display:none">
      // as it's root node, so we need to show it before we inject it
      assignmentRubricDialog.$dialog.html($(html).show())
      assignmentRubricDialog.$dialog
        .find('#rubrics .rubric_container div.rubric-screenreader-title')
        .remove()

      const $container = assignmentRubricDialog.$dialog.dialog('widget')
      this.focusRegion = FocusRegionManager.activateRegion($container[0], {
        shouldContainFocus: true,
        shouldFocusOnOpen: true,
        shouldReturnFocus: false,
      })
    })
  },

  openDialog() {
    if (!this.dialogInited) this.initDialog()
    this.$dialog.dialog('open')
  },
}

export default assignmentRubricDialog
