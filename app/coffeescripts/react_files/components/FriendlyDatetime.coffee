define [
  'react'
  'timezone'
  'underscore'
  'jquery'
  'jquery.instructure_date_and_time'
], (React, tz, _, $) ->


  slowRender = ->
    datetime = @props.datetime
    return React.DOM.time() unless datetime?
    datetime = tz.parse(datetime) unless _.isDate datetime
    fudged = $.fudgeDateForProfileTimezone(datetime)

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


  FriendlyDatetime = React.createClass
    displayName: 'FriendlyDatetime'

    propTypes:
      datetime: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.instanceOf(Date)
      ])

    # The original render function is really slow because of all
    # tz.parse, $.fudge, $.datetimeString, etc.
    # As long as @props.datetime stays same, we don't have to recompute our output.
    # memoizing like this beat React.addons.PureRenderMixin 3x
    render: _.memoize(slowRender, -> @props.datetime)
