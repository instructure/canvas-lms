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

  var EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
  var ACTIVE_ROUTE_REGEX = /^\/(courses|groups|accounts|grades|calendar|conversations|profile)/

  var Navigation = React.createClass({
    propTypes: {
      current_user: React.PropTypes.object.isRequired,
      buttonsToShow: React.PropTypes.object.isRequired
    },

    getDefaultProps() {
      return {
        current_user: null,
        buttonsToShow: null
      };
    },

    getInitialState() {
      return {
        groups: [],
        accounts: [],
        courses: [],
        unread_count: 0,
        isTrayOpen: false,
        type: null,
        activeItem: null
      };
    },

    componentWillMount() {
      this.determineActiveLink();
      $.get('/api/v1/conversations/unread_count', (data) => {
        this.setState({
          unread_count: parseInt(data.unread_count, 10)
        });
      });
    },

    determineActiveLink () {
      var path = window.location.pathname;
      var matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX);
      var activeItem = matchData && matchData[1]
      this.setState({activeItem});
    },

    handleHover(type) {
      if (type === 'courses' && !this.coursesLoaded) {
        this.coursesLoaded = true
        $.get('/api/v1/users/self/favorites/courses', (data) => {
          this.setState({
            courses: data
          });
        });
      }

      if (type === 'groups' && !this.groupsLoaded) {
        this.groupsLoaded = true
        $.get('/api/v1/users/self/groups', (data) => {
          this.setState({
            groups: data
          });
        });
      }

      if (type === 'accounts' && !this.accountsLoaded) {
        this.accountsLoaded = true
        $.get('/api/v1/accounts', (data) => {
          this.setState({
            accounts: data
          });
        });
      }

    },

    handleMenuClick(type) {
      if (this.state.isTrayOpen && (this.state.activeItem === type)) {
        this.closeTray();
      } else if (this.state.isTrayOpen && (this.state.activeItem !== type)) {
        this.openTray(type);
      } else {
        this.openTray(type);
      }
    },

    handleMenuKeyPress(type) {
      if (this.state.isTrayOpen && this.state.activeItem === type) {
        this.closeTray();
      } else if (this.state.isTrayOpen && this.state.activeItem !== type) {
        this.closeTray();
        this.openTray(type);
      } else {
        this.openTray(type);
      }
    },

    openTray(type) {
      this.setState({
        type: type,
        isTrayOpen: true,
        activeItem: type
      });
    },

    closeTray() {
      this.setState({
        isTrayOpen: false
      }, function () {
        this.determineActiveLink();
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
          return <CoursesTray courses={this.state.courses} closeTray={this.closeTray} />;
        case 'groups':
          return <GroupsTray groups={this.state.groups} closeTray={this.closeTray} />;
        case 'accounts':
          return <AccountsTray accounts={this.state.accounts} closeTray={this.closeTray} />;
        case 'profile':
          return <ProfileTray closeTray={this.closeTray} />;
        default:
          return null;
      }
    },

    renderGlobalNavTools () {
      var globalNavTools = window.ENV.GLOBAL_NAV_MENU_ITEMS;
      return globalNavTools.map((tool) => {
        var icon = (tool.tool_data.context_external_tool.name === 'Commons') ? "/images/svg-icons/svg_commons_logo.svg" : ''
        return (
          <MenuItem id={`external_tool_${tool.tool_data.context_external_tool.id}`}
                    href={tool.link} text={tool.tool_data.context_external_tool.name}
                    icon={icon}
                    isActive={this.state.activeItem === 'external_tools'} />
        );
      });
    },

    render() {
      var { current_user } = this.props;
      var { unread_count, groups } = this.state;

      return (
        <ul role="menu" id="menu"
            className="ic-app-header__menu-list"
            aria-label={I18n.t('Main Navigation')}
        >
          <Tray isOpen={this.state.isTrayOpen} onBlur={this.closeTray} closeTimeoutMS={400}>
            {this.renderTrayContent()}
          </Tray>
          {!!this.props.buttonsToShow.hasCourses && (
            <MenuItem id="courses_menu_item" href="/courses" text={I18n.t('Courses')}
                    icon="/images/svg-icons/svg_icon_courses_new_styles.svg"
                    haspopup={true}
                    onHover={this.handleHover.bind(this, 'courses')}
                    onClick={this.handleMenuClick.bind(this, 'courses')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'courses')}
                    isActive={this.state.activeItem === 'courses'} />
          )}

          {!!this.props.buttonsToShow.hasGroups && (
            <MenuItem id="groups_menu_item" href="/groups" text={I18n.t('Groups')}
                    icon="/images/svg-icons/svg_icon_groups_new_styles.svg"
                    onHover={this.handleHover.bind(this, 'groups')}
                    onClick={this.handleMenuClick.bind(this, 'groups')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'groups')}
                    isActive={this.state.activeItem === 'groups'} />
          )}

          {!!this.props.buttonsToShow.hasAccounts && (
            <MenuItem id="accounts_menu_item" href="/accounts" text={I18n.t('Accounts')}
                    icon="/images/svg-icons/svg_icon_accounts_new_styles.svg"
                    onHover={this.handleHover.bind(this, 'accounts')}
                    onClick={this.handleMenuClick.bind(this, 'accounts')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'accounts')}
                    isActive={this.state.activeItem === 'accounts'} />
          )}

          <MenuItem id="grades_menu_item" href="/grades" text={I18n.t('Grades')}
                    icon="/images/svg-icons/svg_icon_grades_new_styles.svg"
                    isActive={this.state.activeItem === 'grades'} />

          <MenuItem id="calendar_menu_item" href="/calendar" text={I18n.t('Calendar')}
                    icon="/images/svg-icons/svg_icon_calendar_new_styles.svg"
                    isActive={this.state.activeItem === 'calendar'} />

          {!current_user.fake_student && (
            <MenuItem id="inbox_menu_item" href="/conversations" text={I18n.t('Inbox')}
                      icon="/images/svg-icons/svg_icon_inbox.svg"
                      isActive={this.state.activeItem === 'inbox'}
                      showBadge={!current_user.disabled_inbox} badgeCount={unread_count} />
          )}

          {this.renderGlobalNavTools()}

          <MenuItem id="profile_menu_item" href="/profile" text={I18n.t('Profile')}
                    isActive={this.state.activeItem === 'profile'}
                    onClick={this.handleMenuClick.bind(this, 'profile')}
                    onKeyPress={this.handleMenuKeyPress.bind(this, 'profile')}
                    avatar={current_user.avatar_image_url} />

        </ul>
      );
    }
  });

  return Navigation;
});
