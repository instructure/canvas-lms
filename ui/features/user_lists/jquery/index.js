/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import ready from '@instructure/ready'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import 'jquery-scroll-to-visible'
import '@canvas/util/templateData'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import {underscoreString} from '@canvas/convert-case'

const I18n = useI18nScope('user_lists')

if (!('INST' in window)) {
  window.INST = {}
}

const UL = (INST.UserLists = {
  init() {
    UL.$form = $('#enroll_users_form')
    UL.$enrollment_blank = $('#enrollment_blank').removeAttr('id').hide()
    UL.$user_lists_processed_person_template = $('#user_lists_processed_person_template')
      .removeAttr('id')
      .detach()
    UL.$user_list_no_valid_users = $('#user_list_no_valid_users')
    UL.$user_list_with_errors = $('#user_list_with_errors')
    UL.$user_list_duplicates_found = $('#user_list_duplicates_found')
    UL.showTextarea()
    UL.$form.find('.cancel_button').click(function () {
      $('.add_users_link').show()
      return UL.$form.hide()
    })
    UL.$form.find('.go_back_button').click(UL.showTextarea)
    UL.$form.find('.verify_syntax_button').click(function (e) {
      e.preventDefault()
      UL.showProcessing()
      return $.ajaxJSON(
        $('#user_lists_path').attr('href'),
        'POST',
        UL.$form.getFormData(),
        UL.showResults
      )
    })
    UL.$form.submit(function (event) {
      event.preventDefault()
      event.stopPropagation()
      UL.$form
        .find('.add_users_button')
        .text(I18n.t('adding_users', 'Adding Users...'))
        .prop('disabled', true)
      return $.ajaxJSON(
        UL.$form.attr('action'),
        'POST',
        UL.$form.getFormData(),
        UL.success,
        UL.failure
      )
    })
    UL.$form
      .find('#enrollment_type')
      .change(function () {
        return $('#limit_privileges_to_course_section_holder').showIf(
          $(this).find(':selected').data('isAdmin') != null
        )
      })
      .change()
    return $('.unenroll_user_link').click(function (event) {
      let $section, $sections, $toDelete, $user
      event.preventDefault()
      event.stopPropagation()
      if ($(this).hasClass('cant_unenroll')) {
        return alert(
          I18n.t(
            'cant_unenroll',
            "This user was automatically enrolled using the campus enrollment system, so they can't be manually removed.  Please contact your system administrator if you have questions."
          )
        )
      } else {
        $user = $(this).parents('.user')
        $sections = $(this).parents('.sections')
        $section = $(this).parents('.section')
        $toDelete = $user
        if ($sections.find('.section:visible').size() > 1) {
          $toDelete = $section
        }
        return $toDelete.confirmDelete({
          message: I18n.t('delete_confirm', 'Are you sure you want to remove this user?'),
          url: $(this).attr('href'),
          success() {
            return $(this).fadeOut(function () {
              return UL.updateCounts()
            })
          },
        })
      }
    })
  },
  success(enrollments) {
    let addedMsg, already_existed
    UL.$form.find('.user_list').val('')
    UL.showTextarea()
    if (!enrollments || !enrollments.length) {
      return false
    }
    already_existed = 0
    $.each(enrollments, function () {
      return (already_existed += UL.addUserToList(this.enrollment))
    })
    addedMsg = I18n.t(
      'users_added',
      {
        one: '1 user added',
        other: '%{count} users added',
      },
      {
        count: enrollments.length - already_existed,
      }
    )
    if (already_existed > 0) {
      addedMsg +=
        ' ' +
        I18n.t(
          'users_existed',
          {
            one: '(1 user already existed)',
            other: '(%{count} users already existed)',
          },
          {
            count: already_existed,
          }
        )
    }
    return $.flashMessage(addedMsg)
  },
  failure(_data) {
    return $.flashError(I18n.t('users_adding_failed', 'Failed to enroll users'))
  },
  showTextarea() {
    UL.$form.find('.add_users_button, .go_back_button, #user_list_parsed').hide()
    UL.$form
      .find('.verify_syntax_button, .cancel_button, #user_list_textarea_container')
      .show()
      .removeAttr('disabled')
    UL.$form
      .find('.verify_syntax_button')
      .prop('disabled', false)
      .text(I18n.t('buttons.continue', 'Continue...'))
    const $user_list = UL.$form
      .find('.user_list')
      .removeAttr('disabled')
      .loadingImage('remove')
      .focus()
    if ($user_list.is(':visible')) {
      return $user_list.select()
    }
  },
  showProcessing() {
    UL.$form
      .find('.verify_syntax_button')
      .prop('disabled', true)
      .text(I18n.t('messages.processing', 'Processing...'))
    return UL.$form.find('.user_list').prop('disabled', true).loadingImage()
  },
  showResults(userList) {
    const $user_lists_processed_people = $('#user_lists_processed_people')
    UL.$form.find('.add_users_button, .go_back_button, #user_list_parsed').show()
    UL.$form
      .find('.add_users_button')
      .prop('disabled', false)
      .focus()
      .text(
        I18n.t(
          'add_n_users',
          {
            one: 'OK Looks Good, Add This 1 User',
            other: 'OK Looks Good, Add These %{count} Users',
          },
          {
            count: userList.users.length,
          }
        )
      )
    UL.$form.find('.verify_syntax_button, .cancel_button, #user_list_textarea_container').hide()
    UL.$form.find('.user_list').removeAttr('disabled').loadingImage('remove')
    $user_lists_processed_people.html('').show()
    if (!userList || !userList.users || !userList.users.length) {
      UL.$user_list_no_valid_users.appendTo($user_lists_processed_people)
      return UL.$form.find('.add_users_button').hide()
    } else {
      if (userList.errored_users && userList.errored_users.length) {
        UL.$user_list_with_errors
          .appendTo($user_lists_processed_people)
          .find('.message_content')
          .text(
            I18n.t(
              'user_parsing_errors',
              {
                one: 'There was 1 error parsing that list of users.',
                other: 'There were %{count} errors parsing that list of users.',
              },
              {
                count: userList.errored_users.length,
              }
            ) +
              ' ' +
              I18n.t(
                'invalid_users_notice',
                'There may be some that were invalid, and you might need to go back and fix any errors.'
              ) +
              ' ' +
              I18n.t(
                'users_to_add',
                {
                  one: 'If you proceed as is, 1 user will be added.',
                  other: 'If you proceed as is, %{count} users will be added.',
                },
                {
                  count: userList.users.length,
                }
              )
          )
      }
      if (userList.duplicates && userList.duplicates.length) {
        UL.$user_list_duplicates_found
          .appendTo($user_lists_processed_people)
          .find('.message_content')
          .text(
            I18n.t(
              'duplicate_users',
              {
                one: '1 duplicate user found, duplicates have been removed.',
                other: '%{count} duplicate user found, duplicates have been removed.',
              },
              {
                count: userList.duplicates.length,
              }
            )
          )
      }
      return $.each(userList.users, function () {
        const userDiv = UL.$user_lists_processed_person_template
          .clone(true)
          .fillTemplateData({
            data: this,
          })
          .appendTo($user_lists_processed_people)
        if (this.user_id) {
          userDiv
            .addClass('existing-user')
            .attr('title', I18n.t('titles.existing_user', 'Existing user'))
        }
        return userDiv.show()
      })
    }
  },
  updateCounts() {
    return $.each(
      ['student', 'teacher', 'ta', 'teacher_and_ta', 'student_and_observer', 'observer'],
      function () {
        return $('.' + this + '_count').text($('.' + this + '_enrollments .user:visible').length)
      }
    )
  },
  addUserToList(enrollment) {
    let $before, $enrollment, $list, already_existed
    const enrollmentType = underscoreString(enrollment.type)
    $list = $('.user_list.' + enrollmentType + 's')
    if (!$list.length) {
      if (enrollmentType === 'student_enrollment' || enrollmentType === 'observer_enrollment') {
        $list = $('.user_list.student_and_observer_enrollments')
      } else {
        $list = $('.user_list.teacher_and_ta_enrollments')
      }
    }
    $list.find('.none').remove()
    enrollment.invitation_sent_at = I18n.t('just_now', 'Just Now')
    $before = null
    $list.find('.user').each(function () {
      const name = $(this).getTemplateData({
        textValues: ['name'],
      }).name
      if (name && enrollment.name && name.toLowerCase() > enrollment.name.toLowerCase()) {
        $before = $(this)
        return false
      }
    })
    enrollment.enrollment_id = enrollment.id
    already_existed = true
    if (!$('#enrollment_' + enrollment.id).length) {
      already_existed = false
      $enrollment = UL.$enrollment_blank
        .clone(true)
        .fillTemplateData({
          textValues: ['name', 'membership_type', 'email', 'enrollment_id'],
          id: 'enrollment_' + enrollment.id,
          hrefValues: ['id', 'user_id', 'pseudonym_id', 'communication_channel_id'],
          data: enrollment,
        })
        .addClass(enrollmentType)
        .removeClass('nil_class user_')
        .addClass('user_' + enrollment.user_id)
        .toggleClass('pending', enrollment.workflow_state !== 'active')
        [$before ? 'insertBefore' : 'appendTo']($before || $list)
        .show()
        .animate(
          {
            backgroundColor: '#FFEE88',
          },
          1000
        )
        .animate(
          {
            display: 'block',
          },
          2000
        )
        .animate(
          {
            backgroundColor: '#FFFFFF',
          },
          2000,
          function () {
            return $(this).css('backgroundColor', '')
          }
        )
      $enrollment
        .find('.enrollment_link')
        .removeClass('enrollment_blank')
        .addClass('enrollment_' + enrollment.id)
      $enrollment.parents('.user_list').scrollToVisible($enrollment)
    }
    UL.updateCounts()
    if (already_existed) {
      return 1
    } else {
      return 0
    }
  },
})

ready(function () {
  return $(UL.init)
})

export default UL
