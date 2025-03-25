//
// Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import {createRoot} from 'react-dom/client'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import {datetimeString} from '@canvas/datetime/date-functions'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import replaceTags from '@canvas/util/replaceTags'
import FilterPeerReview from './react/FilterPeerReview'
import ReviewsPerUserInput from './react/ReviewsPerUserInput'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('assignments.peer_reviews')
const ERROR_MESSAGE = I18n.t('Please select a student')

$(document).ready(() => {
  const peerReviewCountContainer = document.getElementById('reviews_per_user_container')
  const redirectToEditContainer = document.getElementById('redirect_to_edit_button')
  if (peerReviewCountContainer) {
    const root = createRoot(peerReviewCountContainer)
    const initialCount = peerReviewCountContainer.dataset.count ?? '0'
    const setValue = value => {
      const peerReviewCount = document.getElementById('peer_review_count')
      peerReviewCount.value = value
    }
    root.render(
      <View as="div" margin="medium 0 large 0">
        <ReviewsPerUserInput initialCount={initialCount} onChange={setValue} />
      </View>
    )
  }

  if (redirectToEditContainer) {
    const courseId = redirectToEditContainer.dataset.courseid
    const assignmentId = redirectToEditContainer.dataset.assignmentid
    const root = createRoot(redirectToEditContainer)
    const editLink = `/courses/${courseId}/assignments/${assignmentId}/edit?scrollTo=assignment_peer_reviews_fields`
    root.render(
      <Button href={editLink}>
        {I18n.t('Edit Assignment')}
      </Button>
    )
  }

  $('.peer_review').hover(
    function () {
      $('.peer_review.submission-hover').removeClass('submission-hover')
      $(this).addClass('submission-hover')
    },
    function () {
      $(this).removeClass('submission-hover')
    },
  )

  $('.peer_review').focusin(function () {
    $(this).addClass('focusWithin')
  })
  $('.peer_review').focusout(function (event) {
    const $parent = $(this).closest('.peer_review')
    const $newFocus = $(event.related).closest('.peer_review')
    if (!$newFocus.is($parent)) {
      $parent.removeClass('focusWithin')
    }
  })

  $('.peer_review .delete_review_link').click(function (event) {
    event.preventDefault()
    const next = $(this)
      .parents('.peer_review')
      .next()
      .find('a')
      .add($(this).parents('.student_reviews').find('.assign_peer_review_link'))
      .first()
    $(this)
      .parents('.peer_review')
      .confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('messages.cancel_peer_review', 'Cancel this peer review?'),
        success() {
          $(this).fadeOut('slow', function () {
            const $parent = $(this).parents('.peer_reviews')
            $(this).remove()
            if ($parent.find('.assigned').length === 0) {
              $parent.find('.no_requests_message').show()
            }
            next.focus()
          })
        },
      })
  })

  $('.assign_peer_review_link').click(function (event) {
    event.preventDefault()
    // if the form is there and is being shown, then slide it up.
    if ($(this).parents('.student_reviews').find('.form_content form:visible').length) {
      $(this).parents('.student_reviews').find('.form_content form:visible').slideUp()
    } else {
      // otherwise make it and inject it then slide it down
      const $form = $('#assign_peer_review_form').clone(true).removeAttr('id')
      let url = $('.assign_peer_review_url').attr('href')
      let user_id = $(this)
        .parents('.student_reviews')
        .getTemplateData({textValues: ['student_review_id']}).student_review_id
      url = replaceTags(url, 'reviewer_id', user_id)
      $form.find(`select option.student_${user_id}`).prop('disabled', true)
      $(this)
        .parents('.student_reviews')
        .find('.peer_review')
        .each(function () {
          ;({user_id} = $(this).getTemplateData({textValues: ['user_id']}))
          $form.find(`select option.student_${user_id}`).prop('disabled', true)
        })
      $form.attr('action', url)
      $(this).parents('.student_reviews').find('.form_content').empty().append($form)
      $form.slideDown()
    }
  })

  $('#reviewee_id').change(function () {
    const reviewee_id = $(this).val()
    const form = $(this).closest('form')
    const errorsContainer = form.find('#reviewee_errors')[0]

    if (!reviewee_id) {
      const container = $(this)
      if (container) {
        container.addClass('error-outline')
        container.attr('aria-label', ERROR_MESSAGE)
      }

      const root = errorRoots[form.attr('action')] ?? createRoot(errorsContainer)
      errorRoots[form.attr('action')] = root
      root.render(
        <Flex as="div" alignItems="start" margin="0 0 0 0">
          <Flex.Item as="div" margin="0 xx-small xxx-small 0">
            <IconWarningSolid color="error" />
          </Flex.Item>
          <Text size="small" color="danger">
            {ERROR_MESSAGE}
          </Text>
        </Flex>
      )
      return false
    } else {
      const container = $(this)
      if (container) {
        container.removeClass('error-outline')
        container.removeAttr('aria-label')
      }
      errorRoots[form.attr('action')]?.unmount()
      errorRoots[form.attr('action')] = null
    }
  })

  $('#assign_peer_review_form').formSubmit({
    beforeSubmit(data) {
      if (!data.reviewee_id) {
        const form = $(this)
        const errorsContainer = form.find('#reviewee_errors')[0]
        const container = form.find('#reviewee_id')
        if (container) {
          container.addClass('error-outline')
          container.attr('aria-label', ERROR_MESSAGE)
          container.focus()
        }
        const root = errorRoots[form.attr('action')] ?? createRoot(errorsContainer)
        errorRoots[form.attr('action')] = root

        root.render(
          <Flex as="div" alignItems="start" margin="0 0 0 0">
            <Flex.Item as="div" margin="0 xx-small xxx-small 0">
              <IconWarningSolid color="error" />
            </Flex.Item>
            <Text size="small" color="danger">
              {ERROR_MESSAGE}
            </Text>
          </Flex>
        )
        return false
      }
      $(this).loadingImage()
    },
    success(data) {
      $(this).loadingImage('remove')
      $(this).slideUp(function () {
        $(this).remove()
      })
      const $review = $('#review_request_blank').clone(true).removeAttr('id')
      $review.fillTemplateData({
        data: data.assessment_request,
        hrefValues: ['id', 'user_id'],
      })
      $(this)
        .parents('.student_reviews')
        .find('.no_requests_message')
        .slideUp()
        .end()
        .find('.peer_reviews')
        .append($review)
      $review.slideDown()
      $review.find('a').first().focus()
      const assessor_name = $(this).parents('.student_reviews').find('.assessor_name').text()
      const time = datetimeString(data.assessment_request.updated_at)
      $review.find('.reminder_peer_review_link').attr(
        'title',
        I18n.t('titles.reminder', 'Remind %{assessor} about Assessment, last notified %{time}', {
          assessor: assessor_name,
          time,
        }),
      )
      $(this).slideUp(function () {
        $(this).remove()
      })
    },
    error(data) {
      $(this).loadingImage('remove')
      $(this).formErrors(data)
    },
  })

  $('#assign_peer_reviews_form').formSubmit({
    beforeSubmit(data) {
      const textInput = document.getElementById('reviews_per_user_input')
      if (!data.peer_review_count) {
        textInput.focus()
        return false
      } else {
        const input = Number(data.peer_review_count)
        if (!Number.isInteger(input) || input <= 0) {
          textInput.focus()
          return false
        }
        return true
      }
    },
    success(_data) {
      location.reload()
    }
  })

  $('.remind_peer_review_link').click(function (event) {
    event.preventDefault()
    const $link = $(this)
    $link.parents('.peer_review').loadingImage({image_size: 'small'})
    return $.ajaxJSON($link.attr('href'), 'POST', {}, data => {
      $link.parents('.peer_review').loadingImage('remove')
      const assessor_name = $link.parents('.student_reviews').find('.assessor_name').text()
      const time = datetimeString(data.assessment_request.updated_at)
      $link.attr(
        'title',
        I18n.t('titles.remind', 'Remind %{assessor} about Assessment, last notified %{time}', {
          assessor: assessor_name,
          time,
        }),
      )
    })
  })

  $('.remind_peer_reviews_link').click(event => {
    event.preventDefault()
    $('.peer_review.assigned .remind_peer_review_link').click()
  })

  const errorRoots = {}

  ReactDOM.render(<FilterPeerReview />, document.getElementById('filter_peer_review'))
})
