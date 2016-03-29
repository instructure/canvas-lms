define [
  'underscore'
  'timezone'
], (_, tz) ->
  GradingPeriods = {
    dateIsInGradingPeriod: (date, gradingPeriod) ->
      return gradingPeriod.is_last if _.isNull(date)
      startDate = tz.parse(gradingPeriod.start_date)
      endDate = tz.parse(gradingPeriod.end_date)
      startDate < date && date <= endDate
  }
