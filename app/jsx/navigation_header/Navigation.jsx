/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'bower/react-tray/dist/react-tray',
  'jsx/navigation_header/MenuItem',
  'jsx/navigation_header/trays/CoursesTray',
  'jsx/navigation_header/trays/GroupsTray',
  'jsx/navigation_header/trays/AccountsTray',
  'jsx/navigation_header/trays/ProfileTray',
  'jsx/shared/SVGWrapper',
  'jquery'
], (I18n, React, Tray, MenuItem, CoursesTray, GroupsTray, AccountsTray, ProfileTray, SVGWrapper, $) => {

  Tray = React.createFactory(Tray);
  MenuItem = React.createFactory(MenuItem);
  CoursesTray = React.createFactory(CoursesTray);
  GroupsTray = React.createFactory(GroupsTray);
  AccountsTray = React.createFactory(AccountsTray);
  SVGWrapper = React.createFactory(SVGWrapper);

  var Navigation = React.createClass({
    propTypes: {
      current_user: React.PropTypes.object.isRequired
    },

    getDefaultProps() {
      return {
        current_user: null
      };
    },

    getInitialState() {
      return {
        groups: [],
        accounts: [],
        courses: [],
        unread_count: 0,
        isTrayOpen: false,
        type: null
      };
    },

    componentWillMount() {
      $.get('/api/v1/conversations/unread_count', (data) => {
        this.setState({
          unread_count: parseInt(data.unread_count, 10)
        });
      });

      $.get('/api/v1/users/self/groups', (data) => {
        this.setState({
          groups: data
        });
      });

      $.get('/api/v1/courses', (data) => {
        this.setState({
          courses: data
        });
      });

      $.get('/api/v1/accounts', (data) => {
        this.setState({
          accounts: data
        });
      });
    },

    handleMenuClick(type) {
      this.openTray(type);
    },

    handleMenuKeyPress(type) {
      this.openTray(type);
    },

    openTray(type) {
      this.setState({
        type: type,
        isTrayOpen: true
      });
    },

    closeTray() {
      this.setState({
        isTrayOpen: false
      }, function () {
        setTimeout(() => {
          this.setState({
            type: null
          });
        }, 150);
      });
    },

    renderTrayContent() {
      switch(this.state.type) {
        case 'courses':
          return <CoursesTray courses={this.state.courses}/>;
        case 'groups':
          return <GroupsTray groups={this.state.groups} />;
        case 'accounts':
          return <AccountsTray accounts={this.state.accounts} />;
        case 'profile':
          return <ProfileTray />;
        default:
          return null;
      }
    },

    render() {
      var { current_user } = this.props;
      var { unread_count, groups } = this.state;

      // TODO @ryan get real data for global_navigation
      var global_navigation_visibility_for_user = true;
      var global_navigation_tools = [];
      // TODO @ryan get current_user.disabled_inbox/fake_student

      return (
        <ul role="menu" id="menu"
            className="ic-app-header__menu-list"
            aria-label={I18n.t('Main Navigation')}
        >
          <Tray isOpen={this.state.isTrayOpen} onBlur={this.closeTray} closeTimeoutMS={150}>
            {this.renderTrayContent()}
          </Tray>
          {!!this.state.courses.length && (
            <MenuItem id="courses_menu_item" href="/courses" text={I18n.t('Courses')}
                    icon="/images/svg-icons/svg_icon_courses_new_styles.svg"
                    haspopup={true}
                    onClick={this.handleMenuClick.bind(this, 'courses')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'courses')}/>
          )}

          {!!this.state.groups.length && (
            <MenuItem id="groups_menu_item" href="/groups" text={I18n.t('Groups')}
                    icon="/images/svg-icons/svg_icon_courses_new_styles.svg"
                    onClick={this.handleMenuClick.bind(this, 'groups')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'groups')}/>
          )}

          {!!this.state.accounts.length && (
            <MenuItem id="accounts_menu_item" href="/accounts" text={I18n.t('Accounts')}
                    icon="/images/svg-icons/svg_icon_courses_new_styles.svg"
                    onClick={this.handleMenuClick.bind(this, 'accounts')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'accounts')}/>
          )}

          <MenuItem id="grades_menu_item" href="/grades" text={I18n.t('Grades')}
                    icon="/images/svg-icons/svg_icon_grades_new_styles.svg"/>

          <MenuItem id="calendar_menu_item" href="/calendar" text={I18n.t('Calendar')}
                    icon="/images/svg-icons/svg_icon_calendar_new_styles.svg"/>

          {!current_user.fake_student && (
            <li id="inbox_menu_item" className="menu-item ic-app-header__menu-list-item">
              <a href="/conversations" className="menu-item-no-drop ic-app-header__menu-list-link">
                <div className="menu-item-icon-container">
                  <SVGWrapper url="/images/svg-icons/svg_icon_inbox.svg"/>
                  {!current_user.disabled_inbox && (
                    <span className="menu-item__badge" style={{display: unread_count === 0 ? 'none' : ''}}>{unread_count}</span>
                  )}
                </div>
                <div className="menu-item__text">{I18n.t('Inbox')}</div>
              </a>
            </li>
          )}

          <li className="ic-app-header__menu-list-item">
            <a href="#" className="ic-app-header__menu-list-link"
               onClick={this.handleMenuClick.bind(this, 'profile')}
               onKeyPress={this.handleMenuKeyPress.bind(this, 'profile')}
            >
              <div className="menu-item-icon-container">
                <div className="ic-avatar">
                  <img src={current_user.avatar_image_url} className="ic-avatar__image" alt=""/>
                </div>
              </div>
              <div className="menu-item__text">{I18n.t('Profile')}</div>
            </a>
          </li>
        </ul>
      );
    }
  });

  return Navigation;
});
