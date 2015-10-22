define([
  'underscore',
  'react',
  'i18n!dashcards',
  './DashboardCardAction',
  './DashboardColorPicker',
  './CourseActivitySummaryStore'
], function(_, React, I18n, DashboardCardAction, DashboardColorPicker, CourseActivitySummaryStore) {

  var DashboardCard = React.createClass({

    // ===============
    //     CONFIG
    // ===============

    displayName: 'DashboardCard',

    propTypes: {
      courseId: React.PropTypes.string,
      shortName: React.PropTypes.string,
      originalName: React.PropTypes.string,
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

    nicknameInfo: function(nickname) {
      return {
        nickname: nickname,
        originalName: this.props.originalName,
        courseId: this.props.id,
        onNicknameChange: this.handleNicknameChange
      }
    },

    // ===============
    //    LIFECYCLE
    // ===============

    handleNicknameChange: function(nickname){
      this.setState({ nicknameInfo: this.nicknameInfo(nickname) })
    },

    hasLinks: function() {
      return this.props.links.filter(link => !link.hidden).length > 0;
    },

    getInitialState: function() {
      return _.extend({ nicknameInfo: this.nicknameInfo(this.props.shortName) },
        CourseActivitySummaryStore.getStateForCourse(this.props.id))
    },

    componentDidMount: function() {
      CourseActivitySummaryStore.addChangeListener(this.handleStoreChange)
      this.parentNode = this.getDOMNode();
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

      if (this.isMounted()) {
        this.setState({editing: !currentState});
      }
    },

    headerClick: function(e) {
      if (e) { e.preventDefault(); }
      window.location = this.props.href;
    },

    doneEditing: function(){
      if(this.isMounted()) {
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

    unreadCount: function(icon, stream){
      var activityType = {
        'icon-announcement': 'Announcement',
        'icon-assignment': 'Message',
        'icon-discussion': 'DiscussionTopic'
      }[icon];

      stream = stream || [];
      var streamItem = _.find(stream, function(item) {
        // only return 'Message' type if category is 'Due Date' (for assignments)
        return item.type === activityType &&
          (activityType !== 'Message' || item.notification_category === I18n.t('Due Date'))
      });

      // TODO: unread count is always 0 for assignments (see CNVS-21227)
      return (streamItem) ? streamItem.unread_count : 0;
    },

    // ===============
    //    RENDERING
    // ===============

    colorPickerID: function(){
      return "DashboardColorPicker-" + this.props.assetString;
    },

    colorPickerIfEditing: function(){
      if (this.state.editing) {
        return (
          <DashboardColorPicker
            elementID         = {this.colorPickerID()}
            parentNode        = {this.parentNode}
            doneEditing       = {this.doneEditing}
            handleColorChange = {this.handleColorChange}
            assetString       = {this.props.assetString}
            settingsToggle    = {this.refs.settingsToggle}
            backgroundColor   = {this.props.backgroundColor}
            nicknameInfo      = {this.state.nicknameInfo}
          />
        );
      }
    },

    linksForCard: function(){
      return this.props.links.map((link) => {
        if (!link.hidden) {
          return (
            <DashboardCardAction
              unreadCount       = {this.unreadCount(link.icon, this.state.stream)}
              iconClass         = {link.icon}
              linkClass         = {link.css_class}
              path              = {link.path}
              screenReaderLabel = {link.screenreader}
              key               = {link.path}
            />
          );
        }
      });
    },

    render: function () {
      return (
        <div className="ic-DashboardCard" ref="cardDiv">
          <div>
            <div
              className="ic-DashboardCard__background"
              style={
                (window.ENV.use_high_contrast ? 
                  {borderBottomColor: this.props.backgroundColor}
                  :
                  {backgroundColor: this.props.backgroundColor}
                )
              }
            >
              { window.ENV.use_high_contrast ?
                <div
                  className="ic-DashboardCard__hicontrast-color-ribbon"
                  style={{borderTopColor: this.props.backgroundColor}}>
                </div> 
                : 
                null 
              }
              <div className="ic-DashboardCard__header" onClick={this.headerClick}>
                <div className="ic-DashboardCard__header_content">
                  <a className="ic-DashboardCard__link" href="#">
                    <h2 className="ic-DashboardCard__header-title" title={this.props.originalName}>
                      {this.state.nicknameInfo.nickname}
                    </h2>
                  </a>
                  <p className="ic-DashboardCard__header-subtitle">{this.props.courseCode}</p>
                  {
                    this.props.term ? (
                      <p className="ic-DashboardCard__header-term">
                        {this.props.term}
                      </p>
                    ) : null
                  }
                </div>
              </div>
              <button
                aria-expanded = {this.state.editing}
                aria-controls = {this.colorPickerID()}
                className="Button Button--icon-action-rev ic-DashboardCard__header-button"
                onClick={this.settingsClick}
                ref="settingsToggle"
                >
                  <i className="icon-settings" aria-hidden="true" />
                  <span className="screenreader-only">
                    { I18n.t("Choose a color or course nickname for %{course}", { course: this.state.nicknameInfo.nickname}) }
                  </span>
              </button>
            </div>
            <div
              className={ 
                (this.hasLinks() ? 
                  "ic-DashboardCard__action-container"
                  : 
                  "ic-DashboardCard__action-container ic-DashboardCard__action-container--is-empty"
                )
              }
            >
              { this.linksForCard() }
            </div>
          </div>
          { this.colorPickerIfEditing() }
        </div>
      );
    }
  });

  return DashboardCard;
});
