/** @jsx React.DOM */
define([
  'underscore',
  'react',
  'i18n!dashcards',
  './DashboardCardAction',
  './DashboardColorPicker',
  './CourseActivitySummaryStore',
  'compiled/backbone-ext/DefaultUrlMixin',
], function(_, React, I18n, DashboardCardAction, DashboardColorPicker, CourseActivitySummaryStore, DefaultUrlMixin) {

  var DashboardCard = React.createClass({

    // ===============
    //     CONFIG
    // ===============

    displayName: 'DashboardCard',

    propTypes: {
      courseId: React.PropTypes.string,
      shortName: React.PropTypes.string,
      courseCode: React.PropTypes.string,
      assetString: React.PropTypes.string,
      term: React.PropTypes.string,
      href: React.PropTypes.string,
      links: React.PropTypes.array
    },

    getDefaultProps: function () {
      return {
        links: []
      };
    },

    // ===============
    //    LIFECYCLE
    // ===============

    getInitialState: function() {
      return CourseActivitySummaryStore.getStateForCourse(this.props.id)
    },

    componentDidMount: function() {
      CourseActivitySummaryStore.addChangeListener(this.handleStoreChange)
    },

    // ===============
    //    ACTIONS
    // ===============

    handleStoreChange: function() {
      this.setState(
        CourseActivitySummaryStore.getStateForCourse(this.props.id)
      );
    },

    settingsClick: function(e){
      if(e){ e.preventDefault(); }
      this.toggleEditing();
    },

    toggleEditing: function(){
      var currentState = !!this.state.editing;

      if (this.isMounted()){
        this.setState({editing: !currentState});
      }
    },

    doneEditing: function(){
      if(this.isMounted()){
        this.setState({editing: false})
      }
    },

    handleColorChange: function(color){
      var hexColor = "#" + color;
      this.props.handleColorChange(hexColor)
    },

    // ===============
    //    HELPERS
    // ===============

    hasActivity: function(icon, stream){
      var activityType = {
        'icon-announcement': 'Announcement',
        'icon-assignment': 'Message',
        'icon-discussion': 'DiscussionTopic',
      }[icon];

      var stream = stream || [];
      var streamItem = _.find(stream, function(item) {
        return item.type == activityType &&
          (activityType != 'Message' || item.notification_category == I18n.t("Due Date"))
      });
      return streamItem && streamItem.unread_count > 0;
    },

    // ===============
    //    RENDERING
    // ===============

    colorPickerIfEditing: function(){
      if(this.state.editing){
        return (
          <DashboardColorPicker
            parentNode        = {this.getDOMNode()}
            doneEditing       = {this.doneEditing}
            handleColorChange = {this.handleColorChange}
            assetString       = {this.props.assetString}
            settingsToggle    = {this.refs.settingsToggle}
            backgroundColor   = {this.props.backgroundColor} />
        );
      }
    },

    linksForCard: function(){
      return _.map(this.props.links, function(link) {
        if (!link.hidden) {
          return (
            <DashboardCardAction
              hasActivity  = {this.hasActivity(link.icon, this.state.stream)}
              iconClass    = {link.icon}
              path         = {link.path}
              screenreader = {link.screenreader} />
          );
        }
      }, this);
    },

    render: function () {
      return (
        <div className="ic-DashboardCard" ref="cardDiv">
          <div>
            <div className="ic-DashboardCard__background" style={{backgroundColor: this.props.backgroundColor}}>
              <a className="ic-DashboardCard__link" href={this.props.href}>
                <header className="ic-DashboardCard__header">
                  <h2 className="ic-DashboardCard__header-title">{this.props.shortName}</h2>
                  <h3 className="ic-DashboardCard__header-subtitle">{this.props.courseCode}</h3>
                </header>
              </a>
              <button className="Button Button--icon-action-rev ic-DashboardCard__header-button" onClick={this.settingsClick} ref="settingsToggle">
                <i className="icon-settings" />
              </button>
            </div>
            <div className="ic-DashboardCard__action-container">
              {this.linksForCard()}
            </div>
          </div>
          {this.colorPickerIfEditing()}
        </div>
      );
    }
  });

  return DashboardCard;
});
