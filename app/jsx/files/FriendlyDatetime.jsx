define ([
  'i18nObj',
  'react',
  'timezone',
  'underscore',
  'compiled/object/assign',
  'jquery',
  'jquery.instructure_date_and_time'
], function (I18n, React, tz, _, ObjectAssign, $) {


  var slowRender = function () {
    var datetime = this.props.datetime;
    if (!datetime) {
      return (<time></time>);
    }
    if (!_.isDate(datetime)) {
      datetime = tz.parse(datetime);
    }
    var fudged = $.fudgeDateForProfileTimezone(datetime);
    var friendly = $.friendlyDatetime(fudged);

    var timeProps = ObjectAssign(this.props, {
      title: $.datetimeString(datetime),
      dateTime: datetime.toISOString()
    });

    return (
      <time {...timeProps}>
        <span className='visible-desktop'>
          {/* something like: Mar 6, 2014 */}
          {friendly}
        </span>
        <span className='hidden-desktop'>
          {/* something like: 3/3/2014 */}
          {fudged.toLocaleDateString()}
        </span>
      </time>
    );

  };

  var FriendlyDatetime = React.createClass({

    displayName: 'FriendlyDatetime',

    propTypes: {
      datetime: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.instanceOf(Date)
      ])
    },

    // The original render function is really slow because of all
    // tz.parse, $.fudge, $.datetimeString, etc.
    // As long as @props.datetime stays same, we don't have to recompute our output.
    // memoizing like this beat React.addons.PureRenderMixin 3x
    render: _.memoize(slowRender, function () {
      return this.props.datetime;
    })

  });

  return FriendlyDatetime;

});
