define([
  'underscore',
  'jquery',
  'i18n!new_nav',
  'react',
  'react-tray',
  'jsx/navigation_header/trays/CoursesTray',
  'jsx/navigation_header/trays/GroupsTray',
  'jsx/navigation_header/trays/AccountsTray',
  'jsx/navigation_header/trays/ProfileTray',
  'jsx/navigation_header/trays/HelpTray',
  'jsx/shared/SVGWrapper',
  'compiled/fn/preventDefault'
], (_, $, I18n, React, Tray, CoursesTray, GroupsTray, AccountsTray, ProfileTray, HelpTray, SVGWrapper, preventDefault) => {

  var EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/;
  var ACTIVE_ROUTE_REGEX = /^\/(courses|groups|accounts|grades|calendar|conversations|profile)/;
  var ACTIVE_CLASS = 'ic-app-header__menu-list-item--active';

  var UNREAD_COUNT_POLL_INTERVAL = 60000 // 60 seconds

  var TYPE_URL_MAP = {
    courses: '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments',
    groups: '/api/v1/users/self/groups?include[]=can_access',
    accounts: '/api/v1/accounts',
    help: '/help_links'
  };

  var Navigation = React.createClass({
    displayName: 'Navigation',

    getInitialState () {
      return {
        groups: [],
        accounts: [],
        courses: [],
        help: [],
        unread_count: 0,
        unread_count_attempts: 0,
        isTrayOpen: false,
        type: null,
        coursesLoading: false,
        coursesAreLoaded: false,
        accountsLoading: false,
        accountsAreLoaded: false,
        groupsLoading: false,
        groupsAreLoaded: false,
        helpLoading: false,
        helpAreLoaded: false
      };
    },

    componentWillMount () {

      /**
       * Mount up stuff to our existing DOM elements, yes, it's not very
       * React-y, but it is workable and maintainable, plus it doesn't require
       * us to trash what Rails has already rendered.
       */

      //////////////////////////////////
      /// Hover Events
      //////////////////////////////////

      _.forEach(TYPE_URL_MAP, (url, type) => {
        $(`#global_nav_${type}_link`).one('mouseover', () => {
          this.getResource(url, type);
        });
      });

      //////////////////////////////////
      /// Click Events
      //////////////////////////////////

      ['courses', 'groups', 'accounts', 'profile', 'help'].forEach((type) => {
        $(`#global_nav_${type}_link`).on('click', preventDefault(this.handleMenuClick.bind(this, type)));
      });
    },

    componentDidMount () {
      if (this.state.unread_count_attempts == 0) {
        if (window.ENV.current_user_id &&
            !window.ENV.current_user_disabled_inbox &&
            this.unreadCountElement().length != 0 &&
            !(window.ENV.current_user &&
            window.ENV.current_user.fake_student)) {
          this.pollUnreadCount();
        }
      }
    },

    /**
     * Given a URL and a type value, it gets the data and updates state.
     */
    getResource (url, type) {
      var loadingState = {};
      loadingState[`${type}Loading`] = true;
      this.setState(loadingState);

      $.getJSON(url, (data) => {
        var newState = {};
        newState[type] = data;
        newState[`${type}Loading`] = false;
        newState[`${type}AreLoaded`] = true;
        this.setState(newState);
      });
    },

    pollUnreadCount () {
      this.setState({unread_count_attempts: this.state.unread_count_attempts + 1}, function () {
        if (this.state.unread_count_attempts <= 5) {
          $.ajax('/api/v1/conversations/unread_count')
            .then((data) => this.updateUnreadCount(data.unread_count))
            .then(null, console.log.bind(console, 'something went wrong updating unread count'))
            .always(() => setTimeout(this.pollUnreadCount, this.state.unread_count_attempts * UNREAD_COUNT_POLL_INTERVAL));
        }
      });
    },

    unreadCountElement () {
      return this.$unreadCount || (this.$unreadCount = $('#global_nav_conversations_link').find('.menu-item__badge'))
    },

    updateUnreadCount (count) {
      count = parseInt(count, 10);
      this.unreadCountElement().text(count);
      this.unreadCountElement().toggle(count > 0);
    },

    componentWillUpdate (newProps, newState) {
      if (newState.activeItem !== this.state.activeItem) {
        $('.' + ACTIVE_CLASS).removeClass(ACTIVE_CLASS);
        $('#global_nav_' + newState.activeItem + '_link').closest('li').addClass(ACTIVE_CLASS);
      }
    },

    determineActiveLink () {
      var path = window.location.pathname;
      var matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX);
      var activeItem = matchData && matchData[1];
      if (!activeItem) {
        this.setState({activeItem: 'dashboard'})
      } else {
        this.setState({activeItem});
      }
    },

    handleMenuClick (type) {
      // Make sure data is loaded up
      if (TYPE_URL_MAP[type] && !this.state[`${type}AreLoaded`] && !this.state[`${type}Loading`]) {
        this.getResource(TYPE_URL_MAP[type], type);
      }

      if (this.state.isTrayOpen && (this.state.activeItem === type)) {
        this.closeTray();
      } else if (this.state.isTrayOpen && (this.state.activeItem !== type)) {
        this.openTray(type);
      } else {
        this.openTray(type);
      }
    },

    openTray (type) {
      this.setState({
        type: type,
        isTrayOpen: true,
        activeItem: type
      });
    },

    closeTray () {
      this.determineActiveLink();
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

    renderTrayContent () {
      switch (this.state.type) {
        case 'courses':
          return (
            <CoursesTray
              courses={this.state.courses}
              hasLoaded={this.state.coursesAreLoaded}
              closeTray={this.closeTray}
            />
          );
        case 'groups':
          return (
            <GroupsTray
              groups={this.state.groups}
              hasLoaded={this.state.groupsAreLoaded}
              closeTray={this.closeTray}
            />
          );
        case 'accounts':
          return (
            <AccountsTray
              accounts={this.state.accounts}
              hasLoaded={this.state.accountsAreLoaded}
              closeTray={this.closeTray}
            />
          );
        case 'profile':
          return (
            <ProfileTray
              userDisplayName={window.ENV.current_user.display_name}
              userAvatarURL={window.ENV.current_user.avatar_image_url}
              profileEnabled={window.ENV.SETTINGS.enable_profiles}
              eportfoliosEnabled={window.ENV.SETTINGS.eportfolios_enabled}
              closeTray={this.closeTray}
            />
          );
        case 'help':
          return (
            <HelpTray
              links={this.state.help}
              hasLoaded={this.state.helpAreLoaded}
              closeTray={this.closeTray}
            />
          );
        default:
          return null;
      }
    },

    render () {
      return (
        <Tray
          isOpen={this.state.isTrayOpen}
          onBlur={this.closeTray}
          closeTimeoutMS={400}
          getAriaHideElement={() => $('#application')[0]}
          getElementToFocus={() => $('.ReactTray__Content')[0]}
        >
          {this.renderTrayContent()}
        </Tray>
      );
    }
  });

  return Navigation;
});
