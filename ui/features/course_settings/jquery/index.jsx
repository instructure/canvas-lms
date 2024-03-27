/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {tabIdFromElement} from './course_settings_helper'
import * as tz from '@canvas/datetime'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' /* datetimeString, date_field */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import '@canvas/link-enrollment' /* global link_enrollment */
import 'jquery-tinypubsub' /* /\.publish/ */
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import 'jqueryui/sortable'
import 'jqueryui/tabs'

import {GradingSchemesSelector} from '@canvas/grading-scheme'

const I18n = useI18nScope('course_settings')

const GradePublishing = {
  status: null,
  checkup() {
    $.ajaxJSON($('#publish_to_sis_form').attr('action'), 'GET', {}, data => {
      if (!data.hasOwnProperty('sis_publish_overall_status')) return
      GradePublishing.status = data.sis_publish_overall_status
      GradePublishing.update(
        data.hasOwnProperty('sis_publish_statuses') ? data.sis_publish_statuses : {}
      )
    })
  },
  update(messages, requestInProgress) {
    const $publish_grades_link = $('#publish_grades_link'),
      $publish_grades_error = $('#publish_grades_error')
    if (GradePublishing.status === 'published') {
      $publish_grades_error.hide()
      $publish_grades_link.text(I18n.t('Resync grades to SIS'))
      $publish_grades_link.removeClass('disabled')
    } else if (GradePublishing.status === 'publishing' || GradePublishing.status === 'pending') {
      $publish_grades_error.hide()
      $publish_grades_link.text(I18n.t('Syncing grades to SIS...'))
      if (!requestInProgress) {
        setTimeout(GradePublishing.checkup, 5000)
      }
      $publish_grades_link.addClass('disabled')
    } else if (GradePublishing.status === 'unpublished') {
      $publish_grades_error.hide()
      $publish_grades_link.text(I18n.t('Sync grades to SIS'))
      $publish_grades_link.removeClass('disabled')
    } else {
      $publish_grades_error.show()
      $publish_grades_link.text(I18n.t('Resync grades to SIS'))
      $publish_grades_link.removeClass('disabled')
    }
    const $messages = $('#publish_grades_messages')
    $messages.empty()
    $.each(messages, (message, users) => {
      const $message = $('<span/>')
      $message.text(message)
      const $item = $('<li/>')
      $item.append($message)
      $item.append(' - <b>' + users.length + '</b>')
      $messages.append($item)
    })
  },
  publish() {
    if (
      GradePublishing.status === 'publishing' ||
      GradePublishing.status === 'pending' ||
      GradePublishing.status == null
    ) {
      return
    }

    const confirmMessage =
      GradePublishing.status === 'published'
        ? I18n.t('Are you sure you want to resync these grades to the student information system?')
        : I18n.t(
            'Are you sure you want to sync these grades to the student information system? You should only do this if all your grades have been finalized.'
          )

    // eslint-disable-next-line no-alert
    if (!window.confirm(confirmMessage)) {
      return
    }

    const $publish_to_sis_form = $('#publish_to_sis_form')
    GradePublishing.status = 'publishing'
    GradePublishing.update({}, true)
    const successful_statuses = {published: 1, publishing: 1, pending: 1}
    const error = function (_data, _xhr, _status, _error) {
      GradePublishing.status = 'unknown'
      $.flashError(
        I18n.t(
          'Something went wrong when trying to sync grades to the student information system. Please try again later.'
        )
      )
      GradePublishing.update({})
    }
    $.ajaxJSON(
      $publish_to_sis_form.attr('action'),
      'POST',
      $publish_to_sis_form.getFormData(),
      data => {
        if (
          !data.hasOwnProperty('sis_publish_overall_status') ||
          !successful_statuses.hasOwnProperty(data.sis_publish_overall_status)
        ) {
          error(null, null, I18n.t('Invalid SIS sync status'), null)
          return
        }
        GradePublishing.status = data.sis_publish_overall_status
        GradePublishing.update(
          data.hasOwnProperty('sis_publish_statuses') ? data.sis_publish_statuses : {}
        )
      },
      error
    )
  },
}

function checkHomeroomSyncProgress(progress) {
  setTimeout(function () {
    $.ajaxJSON(
      progress.data('url'),
      'GET',
      {},
      data => {
        if (data.workflow_state === 'completed') {
          progress.replaceWith(I18n.t('Last synced: right now'))
        } else {
          checkHomeroomSyncProgress(progress)
        }
      },
      _data => {
        checkHomeroomSyncProgress(progress)
      }
    )
  }, 1000)
}

$(document).ready(function () {
  const $add_section_form = $('#add_section_form'),
    $edit_section_form = $('#edit_section_form'),
    $course_form = $('#course_form'),
    $enrollment_dialog = $('#enrollment_dialog'),
    $tabBar = $('#course_details_tabs')

  const settingsTabs = $tabBar[0].querySelectorAll('ul>li>a[href*="#tab"]')
  // find the index of the tab whose href matches the URL's hash
  const initialTab = Array.from(settingsTabs || []).findIndex(
    t => `#${t.id}` === `${window.location.hash}-link`
  )
  // Sync the location hash with window.history, this fixes some issues with the browser back
  // button when going back to or from the details tab
  if (!window.location.hash) {
    const defaultTab = settingsTabs[0]?.href
    window.history.replaceState(null, null, defaultTab)
  }
  $tabBar
    .on('tabsactivate', (event, ui) => {
      try {
        const $tabLink = ui.newTab.children('a:first-child')
        const hash = new URL($tabLink.prop('href')).hash
        if (window.location.hash !== hash) {
          window.history.pushState(null, null, hash)
        }
        $tabLink.focus()
      } catch (_ignore) {
        // if the URL can't be parsed, so be it.
      }
    })
    .tabs({active: initialTab >= 0 ? initialTab : null})
    .show()

  $add_section_form.formSubmit({
    required: ['course_section[name]'],
    beforeSubmit(_data) {
      $add_section_form
        .find('button')
        .prop('disabled', true)
        .text(I18n.t('buttons.adding_section', 'Adding Section...'))
    },
    success(data) {
      const section = data.course_section,
        $section = $('.section_blank:first').clone(true).attr('class', 'section'),
        $option = $('<option/>')

      $add_section_form
        .find('button')
        .prop('disabled', false)
        .text(I18n.t('buttons.add_section', 'Add Section'))
      $section.fillTemplateData({
        data: section,
        hrefValues: ['id'],
      })
      $section.find('.screenreader-only').each((_index, el) => {
        const $el = $(el)
        $el.text($el.text().replace('%%name%%', section.name))
      })
      $('#course_section_id_holder').show()
      $option
        .val(section.id)
        .text(section.name)
        .addClass('option_for_section_' + section.id)
      $('#sections .section_blank').before($section)
      $section.slideDown()
      $('#course_section_name').val('')
      $('#add_section_form button[type="submit"]').focus()
    },
    error(data) {
      $add_section_form
        .formErrors(data)
        .find('button')
        .prop('disabled', false)
        .text(I18n.t('errors.section', 'Add Section Failed, Please Try Again'))
    },
  })
  $('.cant_delete_section_link').click(function (_event) {
    // eslint-disable-next-line no-alert
    window.alert($(this).attr('title'))
    return false
  })
  $edit_section_form
    .formSubmit({
      beforeSubmit(data) {
        $edit_section_form.hide()
        const $section = $edit_section_form.parents('.section')
        $section.find('.name').text(data['course_section[name]']).show()
        $section.loadingImage({image_size: 'small'})
        return $section
      },
      success(data, $section) {
        const section = data.course_section
        $section.loadingImage('remove')
        $('.option_for_section_' + section.id).text(section.name)
        this.parent().find('.edit_section_link').focus()
      },
      error(data, $section) {
        $section.loadingImage('remove').find('.edit_section_link').click()
        $edit_section_form.formErrors(data)
        this.find('#course_section_name_edit').focus()
      },
    })
    .find(':text')
    .bind('blur', () => {
      $edit_section_form.submit()
    })
    .keycodes('return esc', function (event) {
      if (event.keyString === 'return') {
        $edit_section_form.submit()
      } else {
        $(this).parents('.section').find('.name').show()
        $('body').append($edit_section_form.hide())
      }
    })
  $('.edit_section_link').click(function () {
    const $this = $(this),
      $section = $this.parents('.section'),
      data = $section.getTemplateData({textValues: ['name']})
    $edit_section_form.fillFormData(data, {object_name: 'course_section'})
    $section.find('.name').hide().after($edit_section_form.show())
    $edit_section_form.attr('action', $this.attr('href'))
    $edit_section_form.find(':text:first').focus().select()
    return false
  })
  $('.delete_section_link').click(function () {
    $(this)
      .parents('.section')
      .confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('confirm.delete_section', 'Are you sure you want to delete this section?'),
        success(_data) {
          const $prevItem = $(this).prev()
          const $toFocus = $prevItem.length
            ? $prevItem.find('.delete_section_link,.cant_delete_section_link')
            : $('#sections_tab > a')
          $(this).slideUp(function () {
            $(this).remove()
            $toFocus.focus()
          })
        },
      })
    return false
  })
  $('#nav_form').submit(function () {
    const tabs = []
    $('#nav_enabled_list li').each(function () {
      const tab_id = tabIdFromElement(this)
      if (tab_id !== null) {
        tabs.push({id: tab_id})
      }
    })
    $('#nav_disabled_list li').each(function () {
      const tab_id = tabIdFromElement(this)
      if (tab_id !== null) {
        tabs.push({id: tab_id, hidden: true})
      }
    })

    $('#tabs_json').val(JSON.stringify(tabs))
    return true
  })

  $('.edit_nav_link').click(event => {
    event.preventDefault()
    $('#nav_form').dialog({
      modal: true,
      resizable: false,
      width: 400,
      zIndex: 1000,
    })
  })

  $('#nav_enabled_list, #nav_disabled_list')
    .sortable({
      items: 'li.enabled',
      connectWith: '.connectedSortable',
      axis: 'y',
    })
    .disableSelection()

  $(document).fragmentChange((event, hash) => {
    function handleFragmentType(val) {
      $('#tab-users-link').click()
      $('.add_users_link:visible').click()
      $("#enroll_users_form select[name='enrollment_type']").val(val)
    }
    if (hash === '#add_students') {
      handleFragmentType('StudentEnrollment')
    } else if (hash === '#add_tas') {
      handleFragmentType('TaEnrollment')
    } else if (hash === '#add_teacher') {
      handleFragmentType('TeacherEnrollment')
    }
  })
  $('#course_account_id_lookup').autocomplete({
    source: $('#course_account_id_url').attr('href'),
    select(event, ui) {
      $('#course_account_id').val(ui.item.id)
    },
  })
  $('.move_course_link').click(event => {
    event.preventDefault()
    $('#move_course_dialog')
      .dialog({
        title: I18n.t('titles.move_course', 'Move Course'),
        width: 500,
        modal: true,
        zIndex: 1000,
      })
      .fixDialogButtons()
  })
  $('#move_course_dialog').on('click', '.cancel_button', () => {
    $('#move_course_dialog').dialog('close')
  })

  const grading_scheme_selector = document.getElementById('grading_scheme_selector')

  function renderGradingSchemeSelector() {
    let selectedGradingSchemeId = $('#grading_standard_id').val()
    if (grading_scheme_selector) {
      if (selectedGradingSchemeId === '0' || selectedGradingSchemeId === '') {
        // special value indicating the default grading scheme
        selectedGradingSchemeId = undefined
      }
      ReactDOM.render(
        <GradingSchemesSelector
          canManage={ENV.PERMISSIONS.manage_grading_schemes}
          contextId={ENV.COURSE_ID}
          contextType="Course"
          initiallySelectedGradingSchemeId={selectedGradingSchemeId}
          onChange={gradingSchemeId => handleSelectedGradingSchemeIdChanged(gradingSchemeId)}
          archivedGradingSchemesEnabled={ENV.ARCHIVED_GRADING_SCHEMES_ENABLED}
          shrinkSearchBar
        />,
        grading_scheme_selector
      )
    }
  }
  function handleSelectedGradingSchemeIdChanged(gradingSchemeId) {
    if (gradingSchemeId) {
      $('#grading_standard_id').val(gradingSchemeId)
    } else {
      $('#grading_standard_id').val('')
    }
  }
  $course_form
    .find('.grading_standard_checkbox')
    .change(function () {
      $course_form.find('.grading_standard_link').showIf($(this).prop('checked'))
      if (grading_scheme_selector) {
        if ($(this).prop('checked')) {
          $course_form.find('.grading_scheme_selector').show()
          renderGradingSchemeSelector($('#grading_standard_id').val())
        } else {
          $('#grading_standard_id').val('')
          ReactDOM.render(<></>, grading_scheme_selector)
          $course_form.find('.grading_scheme_selector').hide()
        }
      }
    })
    .change()
  $course_form
    .find('.sync_enrollments_from_homeroom_checkbox')
    .change(function () {
      $course_form.find('.sync_enrollments_from_homeroom_select').showIf($(this).prop('checked'))
    })
    .change()
  $course_form.find('.sync_enrollments_from_homeroom_progress').each(function () {
    const progress = $(this)
    checkHomeroomSyncProgress(progress)
  })
  $course_form.find('#course_conclude_at').change(function () {
    const $warning = $course_form.find('#course_conclude_at_warning')
    const $parent = $(this).parent()
    const date = $(this).data('unfudged-date')
    const isMidnight = tz.isMidnight(date)
    $warning.detach().appendTo($parent).showIf(isMidnight)
    $(this).attr('aria-describedby', isMidnight ? 'course_conclude_at_warning' : null)
  })
  $course_form.formSubmit({
    beforeSubmit(data) {
      // If Restrict Quantitative Data is checked, then the course must have a default grading scheme selected
      const rqdEnabled =
        $course_form.find('#course_restrict_quantitative_data')?.prop('value') === 'true'
      const hasCourseDefaultGradingScheme = !!$course_form
        .find('.grading_standard_checkbox')
        .prop('checked')

      if (rqdEnabled && !hasCourseDefaultGradingScheme) {
        $.flashError(
          I18n.t(
            'errors.restrict_quantitative_data',
            'If "Restrict view of quantitative data" is enabled, then the course must have a default grading scheme enabled.'
          )
        )
        return false
      }

      $(this).loadingImage()
      $(this).find('.readable_license,.account_name,.term_name,.grading_scheme_set').text('...')
      $(this).find('.storage_quota_mb').text(data['course[storage_quota_mb]'])
      $('.course_form_more_options').hide()
    },
    success(_data) {
      $('#course_reload_form').submit()
    },
    error(_data) {
      $(this).loadingImage('remove')
    },
    disableWhileLoading: 'spin_on_success',
  })
  $('.associated_user_link').click(function (event) {
    event.preventDefault()
    const $user = $(this).parents('.user')
    const $enrollment = $(this).parents('.enrollment_link')
    const user_data = $user.getTemplateData({textValues: ['name']})
    const enrollment_data = $enrollment.getTemplateData({
      textValues: ['enrollment_id', 'associated_user_id'],
    })
    link_enrollment.choose(
      user_data.name,
      enrollment_data.enrollment_id,
      enrollment_data.associated_user_id,
      enrollment => {
        if (enrollment) {
          // eslint-disable-next-line @typescript-eslint/no-shadow
          const $user = $('.observer_enrollments .user_' + enrollment.user_id)
          const $enrollment_link = $user.find('.enrollment_link.enrollment_' + enrollment.id)
          $enrollment_link.find('.associated_user.associated').showIf(enrollment.associated_user_id)
          $enrollment_link.fillTemplateData({data: enrollment})
          $enrollment_link
            .find('.associated_user.unassociated')
            .showIf(!enrollment.associated_user_id)
        }
      }
    )
  })
  $('.course_info')
    .not('.uneditable')
    .click(function (event) {
      if (event.target.nodeName === 'INPUT') {
        return
      }
      const $obj = $(this).parents('td').find('.course_form')
      if ($obj.length) {
        $obj.focus().select()
      }
    })
  $('.course_form_more_options_link').click(function (event) {
    event.preventDefault()
    const $moreOptions = $('.course_form_more_options')
    const optionText = $moreOptions.is(':visible')
      ? I18n.t('links.more_options', 'more options')
      : I18n.t('links.fewer_options', 'fewer options')
    $(this).text(optionText)
    const csp = document.getElementById('csp_options')
    if (csp) {
      import('../react/renderCSPSelectionBox')
        .then(({renderCSPSelectionBox}) => renderCSPSelectionBox(csp))
        .catch(() => {
          // We shouldn't get here, but if we do... do something.
          const $message = $('<div />').text(I18n.t('Setting failed to load, try refreshing.'))
          $(csp).append($message)
        })
    }
    $moreOptions.slideToggle()
  })
  $enrollment_dialog.find('.cancel_button').click(() => {
    $enrollment_dialog.dialog('close')
  })

  $enrollment_dialog.find('.re_send_invitation_link').click(function (event) {
    event.preventDefault()
    const $link = $(this)
    $link.text(I18n.t('links.re_sending_invitation', 'Re-Sending Invitation...'))
    const url = $link.attr('href')
    $.ajaxJSON(
      url,
      'POST',
      {},
      _data => {
        $enrollment_dialog.fillTemplateData({
          data: {invitation_sent_at: I18n.t('invitation_sent_now', 'Just Now')},
        })
        $link.text(I18n.t('invitation_sent', 'Invitation Sent!'))
        const $user = $enrollment_dialog.data('user')
        if ($user) {
          $user.fillTemplateData({
            data: {invitation_sent_at: I18n.t('invitation_sent_now', 'Just Now')},
          })
        }
      },
      _data => {
        $link.text(I18n.t('errors.invitation', 'Invitation Failed.  Please try again.'))
      }
    )
  })
  $('.date_entry').datetime_field({alwaysShowTime: true})

  const $default_edit_roles_select = $('#course_default_wiki_editing_roles')
  $default_edit_roles_select.data(
    'current_default_wiki_editing_roles',
    $default_edit_roles_select.val()
  )
  $default_edit_roles_select.change(function () {
    const $this = $(this)
    $('.changed_default_wiki_editing_roles').showIf(
      $this.val() !== $default_edit_roles_select.data('current_default_wiki_editing_roles')
    )
    $('.default_wiki_editing_roles_change').text($this.find(':selected').text())
  })

  $('.re_send_invitations_link').click(function (event) {
    event.preventDefault()
    const $button = $(this),
      oldText = I18n.t('links.re_send_all', 'Re-Send All Unaccepted Invitations')

    $button
      .text(I18n.t('buttons.re_sending_all', 'Re-Sending Unaccepted Invitations...'))
      .prop('disabled', true)
    $.ajaxJSON(
      $button.attr('href'),
      'POST',
      {},
      function (_data) {
        $button
          .text(I18n.t('buttons.re_sent_all', 'Re-Sent All Unaccepted Invitations!'))
          .prop('disabled', false)
        $('.user_list .user.pending').each(function () {
          const $user = $(this)
          $user.fillTemplateData({
            data: {invitation_sent_at: I18n.t('invitation_sent_now', 'Just Now')},
          })
        })
        setTimeout(() => {
          $button.text(oldText)
        }, 2500)
      },
      () => {
        $button
          .text(I18n.t('errors.re_send_all', 'Send Failed, Please Try Again'))
          .prop('disabled', false)
      }
    )
  })

  $('.self_enrollment_checkbox')
    .change(function () {
      $('.open_enrollment_holder').showIf($(this).prop('checked'))
    })
    .change()

  $('#publish_grades_link').click(event => {
    event.preventDefault()
    GradePublishing.publish()
  })
  if (ENV.PUBLISHING_ENABLED) {
    GradePublishing.checkup()
  }

  $('.reset_course_content_button')
    .click(event => {
      event.preventDefault()
      $('#reset_course_content_dialog').dialog({
        title: I18n.t('titles.reset_course_content_dialog_help', 'Reset Course Content'),
        width: 500,
        zIndex: 1000,
        modal: true,
      })

      $('.ui-dialog').focus()
    })
    .fixDialogButtons()
  $('#reset_course_content_dialog .cancel_button').click(() => {
    $('#reset_course_content_dialog').dialog('close')
  })

  $('#course_custom_course_visibility').click(function (_event) {
    $('#customize_course_visibility').toggle(this.checked)
  })

  $('#course_custom_course_visibility').ready(_event => {
    if ($('#course_custom_course_visibility').prop('checked')) {
      $('#customize_course_visibility').toggle(true)
    } else {
      $('#customize_course_visibility').toggle(false)
    }
  })

  const refresh_visibility_options = () => {
    const visibility_options = $('#course_course_visibility').children()
    const course_visibility = $('#course_course_visibility').find(':selected')

    $.each($('#customize_course_visibility select'), (i, sel) => {
      const current = $(sel).find(':selected')

      $(sel).children('option').remove()

      const allow_tighter = ['tighter', 'any'].includes($(sel).data('flexibility'))
      const allow_looser = ['looser', 'any', null, undefined, ''].includes(
        $(sel).data('flexibility')
      )

      let found_current = false
      visibility_options.each((_index, item) => {
        // eslint-disable-next-line eqeqeq
        const isCourseSel = item == course_visibility[0]
        if (isCourseSel) found_current = true
        if (isCourseSel || (allow_tighter && !found_current) || (allow_looser && found_current)) {
          $(item).clone().appendTo($(sel))
        }
      })

      $(sel).val($(current).val())
    })
  }

  $('#course_course_visibility').change(function (_event) {
    refresh_visibility_options()
    $('#customize_course_visibility select').val($('#course_course_visibility').val())
  })

  $('#course_custom_course_visibility').ready(_event => {
    refresh_visibility_options()
  })

  $('#course_show_announcements_on_home_page').change(function (_event) {
    $('#course_home_page_announcement_limit').prop('disabled', !$(this).prop('checked'))
  })

  $('#course_enable_course_paces')
    .change(function () {
      $('#course_paces_caution_text').toggleClass('shown', this.checked)
      $('#homeroom_disabled_tooltip').toggleClass('shown', this.checked)
      $('#course_homeroom_course').prop('disabled', $(this).prop('checked'))
    })
    .trigger('change')

  $('#course_homeroom_course')
    .change(function () {
      $('#pacing_disabled_tooltip').toggleClass('shown', this.checked)
      $('#course_enable_course_paces').prop('disabled', $(this).prop('checked'))
    })
    .trigger('change')

  $('#course_conditional_release').change(function () {
    $('#conditional_release_caution_text').toggleClass('shown', !this.checked)
  })

  window.addEventListener('popstate', () => {
    const openTab = window.location.hash
    if (openTab) {
      document.querySelector(`[href="${openTab}"]`)?.click()
    }
  })
})
