define [
  'i18n!outcomes'
], (I18n) ->

  class CalculationMethodContent
    constructor: (@model) ->
      @calculation_method = @model.get('calculation_method')
      @calculation_int = @model.get('calculation_int')

    present: ->
      @toJSON()[@calculation_method]

    toJSON: ->
      decaying_average:
        method: I18n.t("%{recentInt}/%{remainderInt} Decaying Average", {
          recentInt: @calculation_int
          remainderInt: 100 - @calculation_int
        })
        exampleText: I18n.t("Most recent score counts as 75% of mastery weight, average of all other scores count as 25% of weight."),
        exScores: "1, 3, 2, 4, 5, 3, 6",
        exResult: "5.25"
      n_mastery:
        method: I18n.t("Achieve mastery %{count} times", {
          count: @calculation_int
        })
        exampleText: I18n.t("Must achieve mastery at least 2 times. Scores above mastery will be averaged to calculate final score."),
        exScores: "1, 3, 2, 4, 5, 3, 6",
        exResult: "5.5"
      latest:
        method: I18n.t("Latest Score")
        exampleText: I18n.t("Mastery score reflects the most recent graded assigment or quiz."),
        exScores: "2, 4, 5, 3",
        exResult: "3"
      highest:
        method: I18n.t("Highest Score")
        exampleText: I18n.t("Mastery scrore reflects the highest score of a graded assignment or quiz."),
        exScores: "5, 3, 4, 2",
        exResult: "5"