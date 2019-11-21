/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import I18n from 'i18nObj'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import './jquery.instructure_misc_plugins' /* fragmentChange */
import './jquery.templateData'
import './vendor/jquery.scrollTo'
import 'compiled/behaviors/quiz_selectmenu'

var parentWindow = {
  exists() {
    return window.parent && window.parent.INST
  },

  respondsTo(funcName) {
    return parentWindow.exists() && $.isFunction(window.parent.INST[funcName])
  },

  hasProperty(propName) {
    return parentWindow.exists() && window.parent.INST[propName]
  },

  set(propName, value) {
    if (parentWindow.exists()) {
      window.parent.INST[propName] = value
    }
  },

  get(propName) {
    if (parentWindow.hasProperty(propName)) {
      return window.parent.INST[propName]
    }
  }
}
// end parentWindow object

const data = $('#submission_details').getTemplateData({textValues: ['version_number', 'user_id']})

var scoringSnapshot = {
  snapshot: {
    user_id: data.user_id || null,
    version_number: data.version_number,
    last_question_touched: null,
    question_updates: {},
    fudge_points: 0
  },

  $quizBody: null,

  jumpPosition(question_id) {
    const $question = $('#question_' + question_id)
    if ($question.length > 0) {
      return $question.offset().top - 110
    } else {
      return 0
    }
  },

  checkQuizBody() {
    if (scoringSnapshot.$quizBody === null) {
      scoringSnapshot.$quizBody = $('html,body')
    }
  },

  // Animates scrolling to question if there is no page reload
  jumpToQuestion(question_id) {
    const top = scoringSnapshot.jumpPosition(question_id)
    scoringSnapshot.checkQuizBody()
    scoringSnapshot.$quizBody.stop()
    scoringSnapshot.$quizBody.clearQueue()
    scoringSnapshot.$quizBody.animate({scrollTop: top}, 500)
  },

  // Jumps directly to question upon a page reload
  jumpDirectlyToQuestion(question_id) {
    const top = scoringSnapshot.jumpPosition(question_id)
    scoringSnapshot.checkQuizBody()
    scoringSnapshot.$quizBody.scrollTop(top)
  },

  externallySet: false,

  setSnapshot(data, cancelIfAlreadyExternallySet) {
    if (data) {
      if (cancelIfAlreadyExternallySet && scoringSnapshot.externallySet) {
        return
      }
      scoringSnapshot.externallySet = true
      scoringSnapshot.snapshot = data
      for (const idx in data.question_updates) {
        const question = data.question_updates[idx]
        const $question = $('#question_' + idx)
        if (!ENV.GRADE_BY_QUESTION) {
          $question.addClass('modified_but_not_saved')
        }
        $question
          .find('#question_input_hidden')
          .val(question.points)
          .end()
          .find('.user_points :text')
          .val(I18n.n(question.points))
          .end()
          .find('.question_neutral_comment .question_comment_text textarea')
          .val(question.comments)
      }
      if (parentWindow.hasProperty('lastQuestionTouched') && !ENV.GRADE_BY_QUESTION) {
        scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched)
      } else if (scoringSnapshot.snapshot.last_question_touched && !ENV.GRADE_BY_QUESTION) {
        scoringSnapshot.jumpToQuestion(scoringSnapshot.snapshot.last_question_touched)
      }
    } else if (cancelIfAlreadyExternallySet) {
      if (parentWindow.hasProperty('lastQuestionTouched') && !ENV.GRADE_BY_QUESTION) {
        scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched)
      }
    }
    if (scoringSnapshot.externallySet || cancelIfAlreadyExternallySet) {
      $('#feel_free_to_toggle_message').show()
    }
    if (parentWindow.respondsTo('refreshQuizSubmissionSnapshot')) {
      window.parent.INST.refreshQuizSubmissionSnapshot(scoringSnapshot.snapshot)
    }
  },

  update(question_id, data) {
    scoringSnapshot.snapshot.question_updates[question_id] = data
    scoringSnapshot.snapshot.last_question_touched = question_id
    scoringSnapshot.setSnapshot()
  }
}
// end of scoringSnapshot object

const gradingForm = {
  ensureSelectEventsFire() {
    $('input[type=text]').focus(function() {
      $(this).select()
    })
  },

  scrollToUpdatedQuestion(event, hash) {
    if (hash.indexOf('#question') == 0) {
      const id = hash.substring(10)
      scoringSnapshot.jumpToQuestion(id)
    }
  },

  updateSnapshotFor($question) {
    const question_id = $question.attr('id').substring(9) || null
    if (question_id) {
      const data = {}
      if (!ENV.GRADE_BY_QUESTION) {
        $question.addClass('modified_but_not_saved')
      }
      data.points = numberHelper.parse($question.find('.user_points :text').val())
      data.comments =
        $question.find('.question_neutral_comment .question_comment_text textarea').val() || ''
      scoringSnapshot.update(question_id, data)
    }
    $(document).triggerHandler('score_changed')
  },

  addFudgePoints(points) {
    if (points || points === 0) {
      scoringSnapshot.snapshot.fudge_points = points
      scoringSnapshot.setSnapshot()
    }
    $(document).triggerHandler('score_changed')
  },

  setInitialSnapshot(data) {
    $('#feel_free_to_toggle_message').show()
    if (data) {
      scoringSnapshot.setSnapshot(data)
    } else {
      scoringSnapshot.setSnapshot(null, true)
    }
  },

  onScoreChanged() {
    const $total = $('#after_fudge_points_total')
    let total = 0
    $('.display_question .user_points:visible').each(function() {
      let points =
        numberHelper.parse(
          $(this)
            .find('input.question_input')
            .val()
        ) || 0
      points = Math.round(points * 100.0) / 100.0
      total += points
    })
    let fudge = numberHelper.parse($('#fudge_points_entry').val()) || 0
    fudge = Math.round(fudge * 100.0) / 100.0
    total += fudge
    $total.text(I18n.n(total) || '0')
  },

  questions() {
    return $('.question_holder')
      .map((index, el) => $(el).position().top - 320)
      .toArray()
  },

  onScroll() {
    const qNum = quizNavBar.activateCorrectLink()
    quizNavBar.toggleDropShadow()
  },

  onWindowResize() {
    // Add padding to the bottom of the last question
    const winHeight = $(window).innerHeight()
    const lastHeight = $('div.question_holder:last-child').outerHeight()
    const fixedButtonHeight = $('#speed_update_scores_container').outerHeight()
    const paddingHeight = Math.max(winHeight - lastHeight - 150, fixedButtonHeight)
    $('#update_history_form .quiz-submission.headless').css('marginBottom', paddingHeight + 'px')
  }
}
// end of gradingForm object

var quizNavBar = {
  index: 0,
  windowSize: 10,
  minWidth: 66,
  startingLeftPos: 32,
  navItemWidth: 34,

  initialize() {
    $('.user_points > .question_input').each(function(index) {
      quizNavBar.updateStatusFor($(this))
    })

    if (ENV.GRADE_BY_QUESTION) {
      const questionIndex = parseInt(parentWindow.get('active_question_index'))
      const questionId = $('.q' + questionIndex).data('id')
      if (!isNaN(questionId)) {
        scoringSnapshot.jumpDirectlyToQuestion(questionId)
      }
    }

    quizNavBar.updateWindowSize()
    quizNavBar.setScrollWindowPosition(0)
  },

  size() {
    return $('.question-nav-link').length
  },

  tooBig() {
    return quizNavBar.size() > quizNavBar.windowSize
  },

  updateWindowSize() {
    const fullWidth = $('.quiz-nav, .quiz-nav-fullpage').width()
    const minPadding = 10
    const maxWidth = fullWidth - minPadding * 2
    const itemCount = Math.floor((maxWidth - quizNavBar.minWidth) / quizNavBar.navItemWidth)
    quizNavBar.windowSize = itemCount
    const actualWidth = itemCount * quizNavBar.navItemWidth + quizNavBar.minWidth
    $('.quiz-nav .nav, .quiz-nav-fullpage .nav').animate({width: actualWidth + 'px'}, 10)
  },

  navArrowCache: null,

  $navArrows() {
    if (quizNavBar.navArrowCache === null) {
      quizNavBar.navArrowCache = $('.quiz-nav .nav-arrow, .quiz-nav-fullpage .nav-arrow')
    }
    return quizNavBar.navArrowCache
  },

  navWrapperCache: null,

  $navWrapper() {
    if (quizNavBar.navWrapperCache === null) {
      quizNavBar.navWrapperCache = $('#quiz-nav-inner-wrapper')
    }
    return quizNavBar.navWrapperCache
  },

  updateArrows() {
    if (quizNavBar.tooBig()) {
      quizNavBar.$navArrows().show()
      quizNavBar.$navWrapper().css({position: 'absolute'})
    } else {
      quizNavBar.$navArrows().hide()
      quizNavBar.$navWrapper().css({position: 'relative'})
    }
  },

  toggleDropShadow() {
    // Add shadow to top bar
    $('.quiz-nav').toggleClass('drshadow', $(document).scrollTop() > 0)
  },

  updateStatusFor($scoreInput) {
    try {
      const questionId = $scoreInput.attr('data-question-id')
      const scoreValue = numberHelper.parse($scoreInput.val())
      $('#quiz_nav_' + questionId).toggleClass('complete', !isNaN(scoreValue))
    } catch (err) {
      // do nothing; if there's no status to update, continue with other execution
    }
  },

  activateLink(index) {
    $('.quiz-nav li').removeClass('active')
    $('.q' + index).addClass('active')
  },

  activateCorrectLink() {
    let qNum = 1
    const qArray = gradingForm.questions()
    const docScroll = $(document).scrollTop()
    const $questions = $('.question')
    for (let t = 0; t <= qArray.length; t++) {
      const $question = $($questions[t])
      const currentQuestionNum = t + 1
      if (
        (docScroll > qArray[t] && docScroll < qArray[t + 1]) ||
        (t == qArray.length - 1 && docScroll > qArray[t])
      ) {
        qNum = currentQuestionNum
        parentWindow.set('active_question_index', currentQuestionNum)
        quizNavBar.activateLink(currentQuestionNum)
        $question.addClass('selected_single_question')
      } else {
        $('.q' + currentQuestionNum).removeClass('active')
        $question.removeClass('selected_single_question')
      }
    }
    quizNavBar.setScrollWindowPosition(qNum)
    return qNum
  },

  showQuestionsInWindow(startingIndex, endingIndex) {
    const $navWrapper = $('#quiz-nav-inner-wrapper')
    const leftPosition = quizNavBar.startingLeftPos - startingIndex * quizNavBar.navItemWidth
    const newPos = '' + leftPosition + 'px'
    const currentPos = $navWrapper.css('left')
    if (newPos !== currentPos) {
      $navWrapper.stop()
      $navWrapper.clearQueue()
      $navWrapper.animate({left: leftPosition + 'px'}, 300)
    }
  },

  windowScrollLength() {
    return Math.floor(quizNavBar.windowSize / 2.0)
  },

  setScrollWindowPosition(currentIndex) {
    if (isNaN(currentIndex)) {
      currentIndex = 0
    }
    quizNavBar.index = currentIndex
    quizNavBar.updateArrows()
    if (quizNavBar.tooBig()) {
      let startingIndex = currentIndex - quizNavBar.windowScrollLength()
      const maxStartingIndex = quizNavBar.size() - quizNavBar.windowSize

      if (startingIndex < 0) {
        startingIndex = 0
        quizNavBar.index = 0
      } else if (startingIndex > maxStartingIndex) {
        startingIndex = maxStartingIndex
        quizNavBar.index = maxStartingIndex + quizNavBar.windowScrollLength()
      }

      const endingIndex = startingIndex + quizNavBar.windowSize - 1
      quizNavBar.showQuestionsInWindow(startingIndex, endingIndex)
    }
  },

  previousQuestionBlock() {
    quizNavBar.setScrollWindowPosition(quizNavBar.index - quizNavBar.windowSize)
  },

  nextQuestionBlock() {
    quizNavBar.setScrollWindowPosition(quizNavBar.index + quizNavBar.windowSize)
  }
}
// End of quizNavBar object

$(document).ready(function() {
  gradingForm.ensureSelectEventsFire()

  if (ENV.GRADE_BY_QUESTION) {
    $(document).scroll(gradingForm.onScroll)
    gradingForm.onWindowResize()

    $('.question_holder').click(function() {
      $('.quiz-nav li').removeClass('active')
      $('.question').removeClass('selected_single_question')

      const $questions = $('.question')
      const $question = $(this).find('.question')
      const questionIndex = $questions.index($question) + 1
      parentWindow.set('active_question_index', questionIndex)
      $('.q' + questionIndex).addClass('active')
      $question.addClass('selected_single_question')
    })
  }

  quizNavBar.initialize()

  $(document).fragmentChange(gradingForm.scrollToUpdatedQuestion)

  if (parentWindow.respondsTo('getQuizSubmissionSnapshot')) {
    const data = window.parent.INST.getQuizSubmissionSnapshot(
      scoringSnapshot.snapshot.user_id,
      scoringSnapshot.snapshot.version_number
    )
    gradingForm.setInitialSnapshot(data)
  }

  $(
    '.question_holder .user_points .question_input,.question_holder .question_neutral_comment .question_comment_text textarea'
  ).change(function() {
    const $question = $(this).parents('.display_question')
    const questionId = $question.attr('id')
    gradingForm.updateSnapshotFor($question)
    if ($(this).hasClass('question_input')) {
      const parsed = numberHelper.parse($(this).val())
      const hiddenVal = Number.isNaN(parsed) ? '' : parsed
      $question.find('.question_input_hidden').val(hiddenVal)
      quizNavBar.updateStatusFor($(this))
    }
  })

  $('#fudge_points_entry').change(function() {
    const points = numberHelper.parse($(this).val())
    const parsed = numberHelper.parse($(this).val())
    const hiddenVal = Number.isNaN(parsed) ? '' : parsed
    $('#fudge_points_input').val(hiddenVal)
    gradingForm.addFudgePoints(points)
  })

  $(document).bind('score_changed', gradingForm.onScoreChanged)

  $('.question-nav-link').click(function(e) {
    e.preventDefault()
    const questionId = $(this).attr('data-id')
    scoringSnapshot.jumpToQuestion(questionId)
  })

  $('#nav-prev').click(e => {
    e.preventDefault()
    quizNavBar.previousQuestionBlock()
  })

  $('#nav-next').click(e => {
    e.preventDefault()
    quizNavBar.nextQuestionBlock()
  })

  $(window).resize(() => {
    quizNavBar.updateWindowSize()
    quizNavBar.setScrollWindowPosition(quizNavBar.index)
    gradingForm.onWindowResize()
  })
})

if (ENV.SCORE_UPDATED) {
  $(document).ready(() => {
    if (parentWindow.respondsTo('refreshGrades')) {
      window.parent.INST.refreshGrades()
    }
    if (parentWindow.respondsTo('clearQuizSubmissionSnapshot')) {
      window.parent.INST.clearQuizSubmissionSnapshot(scoringSnapshot.snapshot)
    }
  })
}
