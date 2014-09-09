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
      return React.DOM.time() unless datetime?
      datetime = tz.parse(datetime) unless _.isDate datetime
      fudged = $.fudgeDateForProfileTimezone(datetime)
      timeTitle = $.datetimeString(datetime)


      @transferPropsTo React.DOM.time {
        title: $.datetimeString(datetime)
        dateTime: datetime.toISOString()
      },
        React.DOM.span className: 'visible-desktop',
          # something like: Mar 6, 2014
          $.friendlyDatetime(fudged)
        React.DOM.span className: 'hidden-desktop',
          # something like: 3/3/2014
          fudged.toLocaleDateString()

