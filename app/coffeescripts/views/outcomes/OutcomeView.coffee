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
    , OutcomeContentBase::events

    validations: _.extend
      mastery_points: (data) ->
        if _.isEmpty(data.mastery_points) or parseInt(data.mastery_points) < 0
          I18n.t('mastery_error', 'Must be greater than or equal to 0')
    , OutcomeContentBase::validations

    # Validate before submitting.
    submit: (e) =>
      # set so handlebars doesn't put in placeholder text
      points_possible = _.max _.map(_.pluck(@getFormData().ratings, 'points'), (n) -> parseInt n)
      @model.set {points_possible: points_possible}, silent: true
      super e

    editRating: (e) =>
      e.preventDefault()
      $(e.currentTarget).parent().hide().next().show()

    # won't allow deleting the last rating
    deleteRating: (e) =>
      e.preventDefault()
      if @$('.rating').length > 1
        $(e.currentTarget).closest('td').remove()
        @updateRatings()

    saveRating: (e) ->
      e.preventDefault()
      $editWrapper = $(e.currentTarget).parents('.edit:first')
      $showWrapper = $editWrapper.prev()
      $showWrapper.find('h5').text($editWrapper.find('input.outcome_rating_description').val())
      $showWrapper.find('.points').text($editWrapper.find('input.outcome_rating_points').val())
      $editWrapper.hide()
      $showWrapper.show()

    insertRating: (e) =>
      e.preventDefault()
      rating = $ criterionTemplate description: '', points: '', _index: 99
      $(e.currentTarget).closest('.rating').after rating
      rating.find('.show').hide().next().show(200)
      rating.find('.edit input:first').focus()
      @updateRatings()

    # Update rating form field elements and the total.
    updateRatings: ->
      total = 0
      for r in @$('.rating')
        rating = $(r).find('.outcome_rating_points').val()
        total = _.max [total, parseInt rating] if rating
        index = _i
        for i in $(r).find('input')
          # reset indices
          $(i).attr 'name', i.name.replace /\[[0-9]+\]/, "[#{index}]"
      points = @$('.points_possible')
      points.html points.html().replace /[0-9]+/, total

    showRatingDialog: (e) =>
      e.preventDefault()
      $("#outcome_criterion_dialog").dialog(
        autoOpen: false
        title: I18n.t("outcome_criterion", "Learning Outcome Criterion")
        width: 400
      ).dialog('open')

    render: ->
      data = @model.toJSON()
      switch @state
        when 'edit'
          @$el.html outcomeFormTemplate data
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
          @readyForm()
        when 'loading'
          @$el.empty()
        else # show
          @$el.html outcomeTemplate _.extend data, readOnly: @readOnly()
      @$('input:first').focus()
      this
