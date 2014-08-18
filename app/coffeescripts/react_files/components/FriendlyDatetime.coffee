define [
  'react'
  'timezone'
  'underscore'
  'jquery'
  'jquery.instructure_date_and_time'
], (React, tz, _, $) ->

  FriendlyDatetime = React.createClass

    propTypes:
      datetime: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.instanceOf(Date)
      ])

    render: ->
      datetime = @props.datetime
      return unless datetime?
      datetime = tz.parse(datetime) unless _.isDate datetime
      fudged = $.fudgeDateForProfileTimezone(datetime)
      timeTitle = $.datetimeString(datetime)

      @transferPropsTo(React.DOM.time({
        title: $.datetimeString(datetime)
        dateTime: datetime.toISOString()
      }, $.friendlyDatetime(fudged)))