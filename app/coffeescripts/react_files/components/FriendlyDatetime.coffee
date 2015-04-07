define [
  'react'
  'timezone'
  'underscore'
  'compiled/react/shared/utils/withReactElement'
  'compiled/object/assign'
  'jquery'
  'jquery.instructure_date_and_time'
], (React, tz, _, withReactElement, ObjectAssign, $) ->


  slowRender = withReactElement ->
    datetime = @props.datetime
    return time() unless datetime?
    datetime = tz.parse(datetime) unless _.isDate datetime
    fudged = $.fudgeDateForProfileTimezone(datetime)

    time ObjectAssign(@props, {
      title: $.datetimeString(datetime)
      dateTime: datetime.toISOString()
    }),
      span className: 'visible-desktop',
        # something like: Mar 6, 2014
        $.friendlyDatetime(fudged)


      span className: 'hidden-desktop',
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
