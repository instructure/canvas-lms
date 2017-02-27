#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'i18n!outcomes'
  'jsx/shared/helpers/numberHelper'
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomeContentBase'
  'compiled/views/outcomes/CalculationMethodFormView'
  'jst/outcomes/outcome'
  'jst/outcomes/outcomeForm'
  'jst/outcomes/_criterion' # for outcomeForm
  'jqueryui/dialog'
], (I18n, numberHelper, $, _, OutcomeContentBase, CalculationMethodFormView,
  outcomeTemplate, outcomeFormTemplate, criterionTemplate) ->

  # For outcomes in the main content view.
  class OutcomeView extends OutcomeContentBase
    @child 'calculationMethodFormView', 'div.outcome-calculation-method-form'

    events: _.extend
      'click .outcome_information_link': 'showRatingDialog'
      'click .edit_rating': 'editRating'
      'click .delete_rating_link': 'deleteRating'
      'click .save_rating_link': 'saveRating'
      'click .insert_rating': 'insertRating'
      'change .calculation_method' : 'updateCalcMethod'
      'keyup .mastery_points' : 'changeMasteryPoints'
    , OutcomeContentBase::events

    validations: _.extend
      display_name: (data) ->
        if data.display_name.length > 255
          I18n.t('length_error', 'Must be 255 characters or less')
      mastery_points: (data) ->
        if _.isNaN(data.mastery_points) or data.mastery_points < 0
          I18n.t('mastery_error', 'Must be greater than or equal to 0')
    , OutcomeContentBase::validations

    constructor: ({@setQuizMastery, @useForScoring}) ->
      super
      @calculationMethodFormView = new CalculationMethodFormView({
        model: @model
      })

    # overriding superclass
    getFormData: ->
      data = super()
      data['mastery_points'] = numberHelper.parse(data['mastery_points'])
      data['ratings'] = _.map(data['ratings'], (rating) ->
        _.extend(rating, {points: numberHelper.parse(rating['points'])}))
      if data.calculation_method in ['highest', 'latest']
        delete data.calculation_int
      else
        data.calculation_int = parseInt(numberHelper.parse(data.calculation_int))
      data

    editRating: (e) =>
      e.preventDefault()
      $showWrapper = $(e.currentTarget).parents('.show:first')
      $editWrapper = $showWrapper.next()

      $showWrapper.attr('aria-expanded', 'false').hide()
      $editWrapper.attr('aria-expanded', 'true').show()
      $editWrapper.find('.outcome_rating_description').focus()

    # won't allow deleting the last rating
    deleteRating: (e) =>
      e.preventDefault()
      if @$('.rating').length > 1
        deleteBtn = $(e.currentTarget)
        focusTarget = deleteBtn
                     .closest('.rating')
                     .prev()
                     .find('.insert_rating')
        if focusTarget.length == 0
          focusTarget = deleteBtn
                       .closest('.rating')
                       .next()
                       .find('.edit_rating')
        deleteBtn.closest('td').remove()
        focusTarget.focus()
        @updateRatings()

    saveRating: (e) ->
      e.preventDefault()
      $editWrapper = $(e.currentTarget).parents('.edit:first')
      $showWrapper = $editWrapper.prev()
      $showWrapper.find('h5').text($editWrapper.find('input.outcome_rating_description').val())
      points = numberHelper.parse($editWrapper.find('input.outcome_rating_points').val())
      if _.isNaN(points)
        points = 0
      else
        points = I18n.n(points, {precision: 2, strip_insignificant_zeros: true})
      $showWrapper.find('.points').text(points)
      $editWrapper.attr('aria-expanded', 'false').hide()
      $showWrapper.attr('aria-expanded', 'true').show()
      $showWrapper.find('.edit_rating').focus()
      @updateRatings()

    insertRating: (e) =>
      e.preventDefault()
      $rating = $ criterionTemplate description: '', points: '', _index: 99
      $(e.currentTarget).closest('.rating').after $rating
      $rating.find('.show').hide().next().show(200)
      $rating.find('.edit input:first').focus()
      @updateRatings()

    updateCalcMethod: (e) =>
      e?.preventDefault()
      @model.set({
        calculation_method: $(e.target).val()
      })

    changeMasteryPoints: (e) ->
      clearTimeout(@timeout) if @timeout
      @timeout = setTimeout(=>
        val = numberHelper.parse($(e.target).val())
        return if _.isNaN(val)
        if 0 <= val <= @model.get('points_possible')
          @model.set({
            mastery_points: val
          })
          @calculationMethodFormView?.render()
      , 500)

    # Update rating form field elements and the total.
    updateRatings: ->
      total = 0
      for r in @$('.rating')
        rating = $(r).find('.outcome_rating_points').val() or 0
        total = _.max [total, numberHelper.parse(rating)]
        index = _i
        for i in $(r).find('input')
          # reset indices
          $(i).attr 'name', i.name.replace /\[[0-9]+\]/, "[#{index}]"
      points = @$('.points_possible')
      points.html $.raw I18n.t("%{points_possible} Points", {points_possible:
        I18n.n(total, {precision: 2, strip_insignificant_zeros: true})})
      @model.set({
        points_possible: total
      })

    showRatingDialog: (e) =>
      e.preventDefault()
      $("#outcome_criterion_dialog").dialog(
        autoOpen: false
        title: I18n.t("outcome_criterion", "Learning Outcome Criterion")
        width: 400
        close: -> $(e.target).focus()
      ).dialog('open')

    screenreaderTitleFocus: ->
      @$(".screenreader-outcome-title").focus()

    render: ->
      data = @model.present()
      data.html_url = ENV.CONTEXT_URL_ROOT+'/outcomes/'+data.id
      @calculationMethodFormView.state = @state
      switch @state
        when 'edit', 'add'
          @$el.html outcomeFormTemplate _.extend data,
            calculationMethods: @model.calculationMethods()
          @readyForm()
        when 'loading'
          @$el.empty()
        else # show
          data['points_possible'] ||= 0
          data['mastery_points'] ||= 0
          can_move = !@readOnly() && ENV.PERMISSIONS?.manage_outcomes
          can_edit = can_move && @model.isNative() && @model.get('can_edit')
          can_remove = can_move && @model.outcomeLink.can_unlink

          @$el.html outcomeTemplate _.extend data,
            can_move: can_move,
            can_edit: can_edit,
            can_remove: can_remove,
            setQuizMastery: @setQuizMastery,
            useForScoring: @useForScoring,
            isLargeRoster: ENV.IS_LARGE_ROSTER,
            assessedInContext: @model.outcomeLink.assessed || (@model.isNative() && @model.get('assessed'))

      @$('input:first').focus()
      @screenreaderTitleFocus()
      @_afterRender()
      this
