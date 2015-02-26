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
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomeContentBase'
  'jst/outcomes/outcome'
  'jst/outcomes/outcomeForm'
  'jst/outcomes/_criterion' # for outcomeForm
  'jqueryui/dialog'
], (I18n, $, _, OutcomeContentBase, outcomeTemplate, outcomeFormTemplate, criterionTemplate) ->

  # For outcomes in the main content view.
  class OutcomeView extends OutcomeContentBase

    events: _.extend
      'click .outcome_information_link': 'showRatingDialog'
      'click .edit_rating': 'editRating'
      'click .delete_rating_link': 'deleteRating'
      'click .save_rating_link': 'saveRating'
      'click .insert_rating': 'insertRating'
      'change .calculation_method' : 'updateCalcInt'
    , OutcomeContentBase::events

    validations: _.extend
      mastery_points: (data) ->
        if _.isEmpty(data.mastery_points) or parseFloat(data.mastery_points) < 0
          I18n.t('mastery_error', 'Must be greater than or equal to 0')
    , OutcomeContentBase::validations

    constructor: ({@setQuizMastery, @useForScoring}) ->
      super

    # Validate before submitting.
    submit: (e) =>
      # set so handlebars doesn't put in placeholder text
      points_possible = _.max _.map(_.pluck(@getFormData().ratings, 'points'), (n) -> parseFloat n)
      @model.set {points_possible: points_possible}, silent: true
      super e

    # overriding superclass
    getFormData: ->
      data = super()
      delete data.calculation_int if data.calculation_method in ['highest', 'latest']
      data

    editRating: (e) =>
      e.preventDefault()
      $(e.currentTarget).parent().hide()

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
      $showWrapper.find('.points').text($editWrapper.find('input.outcome_rating_points').val() or 0)
      $editWrapper.attr('aria-expanded', false).hide()
      $showWrapper.show()
      $showWrapper.find('.edit_rating').focus()
      @updateRatings()

    insertRating: (e) =>
      e.preventDefault()
      $rating = $ criterionTemplate description: '', points: '', _index: 99
      $(e.currentTarget).closest('.rating').after $rating
      $rating.find('.show').hide().next().show(200)
      $rating.find('.edit input:first').focus()
      @updateRatings()

    CALC_METHODS = {
      'decaying_average' : {
        friendlyString: I18n.t("Decaying Average")
        showCalcIntSettingBox: true
        calcIntLabel: I18n.t("Last Item: ")
        calcIntRangeInfo: I18n.t('Between 1% and 99%')
        calcIntExample: I18n.t("Last item is 75% of mastery.  Average of 'the rest' is 25% of mastery")
        calcIntExampleLine1: I18n.t("1 - Item scores: 2, 4, 2, 5")
        calcIntExampleLine2: I18n.t("2 - 'The rest' item average: (2 + 4 + 2) / 3 = 3")
        calcIntExampleLine3: I18n.t("3 - Calculated mastery score: 5(0.75) + 3(0.25) = 4.5")
      },
      'n_mastery' : {
        friendlyString: I18n.t("n Number of Times")
        showCalcIntSettingBox: true
        calcIntLabel: I18n.t('Items: ')
        calcIntRangeInfo: I18n.t('Between 2 and 5')
        calcIntExample: I18n.t("Must achieve mastery at least 2 times.  Must also complete 2 items for calculation. Scores above mastery will be averaged to calculate final score.")
        calcIntExampleLine1: I18n.t("1- Item Scores: 1, 3, 2, 4, 5, 3, 6")
        calcIntExampleLine2: I18n.t("2- Final score: 5.5")
        calcIntExampleLine3: ""
      },
      'latest' : {
        friendlyString: I18n.t("Most Recent Score")
        showCalcIntSettingBox: false
        calcIntLabel: ""
        calcIntRangeInfo: ""
        calcIntExample: I18n.t("Use the most recent score")
        calcIntExampleLine1: I18n.t("1 - Item scores: 1, 2, 2, 3, 5, 5, 3")
        calcIntExampleLine2: I18n.t("2 - Most recent score: 3")
        calcIntExampleLine3: ""
      },
      'highest' : {
        friendlyString: I18n.t("Highest Score")
        showCalcIntSettingBox: false
        calcIntLabel: ""
        calcIntRangeInfo: ""
        calcIntExample: I18n.t("Use the highest score")
        calcIntExampleLine1: I18n.t("1 - Item scores: 3, 2, 2, 4, 1, 3, 4")
        calcIntExampleLine2: I18n.t("2 - Highest score: 4")
        calcIntExampleLine3: ""
      }
    }

    updateCalcInt: (e) =>
      e.preventDefault() if e

      if !!@$el.find('#calculation_method').val()
        calc_method = @$el.find('#calculation_method').val()
      else
        calc_method = @$el.find('#calculation_method').data('calculation-method')

      intInfo = CALC_METHODS[calc_method]

      if intInfo.showCalcIntSettingBox
        @$el.find('#calculation_int_left_side').show()
      else
        @$el.find('#calculation_int_left_side').hide()
      @$el.find('#calculation_int_label').text(intInfo.calcIntLabel)
      @$el.find('#calculation_int_range_info').text(intInfo.calcIntRangeInfo)
      @$el.find('#calculation_int_example').text(intInfo.calcIntExample)
      @$el.find('#calculation_int_example_line_1').text(intInfo.calcIntExampleLine1)
      @$el.find('#calculation_int_example_line_2').text(intInfo.calcIntExampleLine2)
      @$el.find('#calculation_int_example_line_3').text(intInfo.calcIntExampleLine3)

      if @state in ['edit', 'add'] && calc_method in ['n_mastery', 'decaying_average']
        calc_int_el = @$el.find('#calculation_int')
        calc_int = parseInt(calc_int_el.val())

        switch calc_method
          when 'n_mastery'
            calc_int_el.val("5") if !calc_int || calc_int > 5
          when 'decaying_average'
            calc_int_el.val("65") if !calc_int || calc_int == 5

    # Update rating form field elements and the total.
    updateRatings: ->
      total = 0
      for r in @$('.rating')
        rating = $(r).find('.outcome_rating_points').val() or 0
        total = _.max [total, parseFloat rating]
        index = _i
        for i in $(r).find('input')
          # reset indices
          $(i).attr 'name', i.name.replace /\[[0-9]+\]/, "[#{index}]"
      points = @$('.points_possible')
      points.html $.raw points.html().replace(/[0-9/.]+/, total)

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
      data = @model.toJSON()
      data.html_url = ENV.CONTEXT_URL_ROOT+'/outcomes/'+data.id
      switch @state
        when 'edit'
          @$el.html outcomeFormTemplate _.extend data,
            calculationMethods: CALC_METHODS
          @readyForm()
        when 'add'
          @$el.html outcomeFormTemplate _.extend data,
            points_possible: 5
            mastery_points: 3
            ratings: [
              description: I18n.t("criteria.exceeds_expectations", "Exceeds Expectations")
              points: 5
            ,
              description: I18n.t("criteria.meets_expectations", "Meets Expectations")
              points: 3
            ,
              description: I18n.t("criteria.does_not_meet_expectations", "Does Not Meet Expectations")
              points: 0]
            calculation_method: 'decaying_average'
            calculation_int: 65
            calculationMethods: CALC_METHODS
          @readyForm()
        when 'loading'
          @$el.empty()
        else # show
          data['points_possible'] ||= 0
          data['mastery_points'] ||= 0
          @$el.html outcomeTemplate _.extend data,
            readOnly: @readOnly(),
            native: @model.outcomeLink.outcome.context_id == @model.outcomeLink.context_id && @model.outcomeLink.outcome.context_type == @model.outcomeLink.context_type
            setQuizMastery: @setQuizMastery,
            useForScoring: @useForScoring,
            isLargeRoster: ENV.IS_LARGE_ROSTER,
            calc_method_str: CALC_METHODS[data.calculation_method].friendlyString

      @updateCalcInt() unless @state == 'loading'
      @$('input:first').focus()
      @screenreaderTitleFocus()
      this
