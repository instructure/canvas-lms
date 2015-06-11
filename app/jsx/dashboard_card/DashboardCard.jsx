/** @jsx React.DOM */
define([
  'underscore',
  'react',
  'i18n!dashcards',
  './DashboardCardAction',
  './CourseActivitySummaryStore'
], function(_, React, I18n, DashboardCardAction, CourseActivitySummaryStore) {
  var DashboardCardBackground = {
    // 'Constants'
    allColors: [
      '#008400',
      '#91349B',
      '#E1185C',
      '#D41E00',
      '#0076B8',
      '#626E7B',
      '#4D3D4D',
      '#254284',
      '#9F7217',
      '#177B63',
      '#324A4D',
      '#3C4F36'
    ],
    storageKeyPrefix: 'canvas.dashboard.color.',
    usedColorStorageKey: 'canvas.dashboard.usedColors',

    // Internal
    availableColors: function() {
      var usedColorsFromStorage = this.usedColors(),
        usedColorsByFrequency = _.groupBy(usedColorsFromStorage, function(x) {
          return _.filter(usedColorsFromStorage, function(y) { return x == y }).length
        }),
        usedColors = _.uniq(usedColorsByFrequency[
          _.chain(usedColorsByFrequency).keys().max().value()
        ]),
        availableColors = _.difference(this.allColors, usedColors);

      return _.isEmpty(availableColors) ? this.allColors : availableColors;
    },
    setUsedColor: function(color) {
      var usedColors = this.usedColors();
      usedColors.push(color);
      localStorage[this.usedColorStorageKey] = JSON.stringify(usedColors);
    },
    usedColors: function() {
      var usedColors = localStorage[this.usedColorStorageKey];

      return _.isUndefined(usedColors) ? [] : JSON.parse(usedColors)
    },

    // Public
    colorFor: function(courseId) {
      var color,
        storageKey = this.storageKeyPrefix + courseId;

      if (_.isUndefined(localStorage[storageKey])) {
        color = _.sample(this.availableColors());
        localStorage[storageKey] = color;
        this.setUsedColor(color);
        return color;
      } else {
        return localStorage[storageKey];
      }
    }
  };

  var ActivityIndicator = function(icon, state) {
    var activityType = {
      'icon-announcement': 'Announcement',
      'icon-assignment': 'Message',
      'icon-discussion': 'DiscussionTopic',
    }[icon],
      stream = state.stream || [],
      streamItem = _.find(stream, function(item) {
        if (item.type == activityType) {
          if (activityType == 'Message') {
            return item.notification_category == I18n.t("Due Date")
          } else {
            return true
          }
        }
      })

    return {
      hasActivity: function() {
        return _.isUndefined(streamItem) ? false : streamItem.unread_count > 0
      }
    }
  };

  var DashboardCard = React.createClass({
    displayName: 'DashboardCard',

    propTypes: {
      courseId: React.PropTypes.string,
      shortName: React.PropTypes.string,
      courseCode: React.PropTypes.string,
      term: React.PropTypes.string,
      href: React.PropTypes.string,
      links: React.PropTypes.array
    },

    getDefaultProps: function () {
      return {
        links: []
      };
    },

    // Life Cycle
    getInitialState: function() {
      return CourseActivitySummaryStore.getStateForCourse(this.props.id)
    },

    componentDidMount: function() {
      CourseActivitySummaryStore.addChangeListener(this.handleStoreChange)
    },

    handleStoreChange: function() {
      this.setState(CourseActivitySummaryStore.getStateForCourse(this.props.id));
    },

    // Helpers
    backgroundColor: function() {
      return {
        backgroundColor: DashboardCardBackground.colorFor(this.props.id)
      };
    },

    hasActivity: function(icon) {
      return new ActivityIndicator(icon, this.state).hasActivity()
    },

    render: function () {
      var links = _.map(this.props.links, function(link) {
        if (!link.hidden) {
          return (
            <DashboardCardAction iconClass={link.icon}
              hasActivity={this.hasActivity(link.icon)}
              path={link.path}
              screenreader={link.screenreader}
            />
          );
        }
      }, this);
      return (
        <div className="ic-DashboardCard">
          <div className="ic-DashboardCard_header" style={this.backgroundColor()}>
            <a className="ic-DashboardCard_header_link" href={this.props.href}>
              <h2 className="ic-DashboardCard_header-title">{this.props.shortName}</h2>
              <h3 className="ic-DashboardCard_header-subtitle">{this.props.courseCode}</h3>
            </a>
          </div>
          <div className="ic-DashboardCard_action-container">
            {links}
          </div>
        </div>
      );
    }
  });

  return DashboardCard;
});
