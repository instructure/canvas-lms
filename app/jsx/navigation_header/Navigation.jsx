/** @jsx React.DOM */

define([
  'underscore',
  'jquery',
  'i18n!new_nav',
  'react',
  'bower/react-tray/dist/react-tray',
  'jsx/navigation_header/trays/CoursesTray',
  'jsx/navigation_header/trays/GroupsTray',
  'jsx/navigation_header/trays/AccountsTray',
  'jsx/navigation_header/trays/ProfileTray',
  'jsx/shared/SVGWrapper',
  'compiled/fn/preventDefault'
], (_, $, I18n, React, Tray, CoursesTray, GroupsTray, AccountsTray, ProfileTray, SVGWrapper, preventDefault) => {

  var EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/;
  var ACTIVE_ROUTE_REGEX = /^\/(courses|groups|accounts|grades|calendar|conversations|profile)/;
  var ACTIVE_CLASS = 'ic-app-header__menu-list-item--active';

  var Navigation = React.createClass({
    displayName: 'Navigation',

    getInitialState () {
      return {
        groups: [],
        accounts: [],
        courses: [],
        unread_count: 0,
        isTrayOpen: false,
        type: null,
        coursesAreLoaded: false,
        accountsAreLoaded: false,
        groupsAreLoaded: false
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

      _.forEach({
        courses: '/api/v1/users/self/favorites/courses',
        groups: '/api/v1/users/self/groups',
        accounts: '/api/v1/accounts'
      }, (url, type) => {
        $(`#global_nav_${type}_link`).one('mouseover', () => {
          $.get(url, (data) => {
            var newState = {};
            newState[type] = data;
            this.setState(newState);
          });
        });
      });

      //////////////////////////////////
      /// Click Events
      //////////////////////////////////

      ['courses', 'groups', 'accounts', 'profile'].forEach((type) => {
        $(`#global_nav_${type}_link`).on('click', preventDefault(this.handleMenuClick.bind(this, type)));
      });

      //////////////////////////////////
      /// Other Events
      //////////////////////////////////
      if (window.ENV.current_user_id) {
        // Put this in a function so we can call it on an interval to do some
        // polling.
        var updateCount = () => {
          $.ajax({
            url: '/api/v1/conversations/unread_count',
            type: 'GET',
            success: (data) => {
              var parsedInt = parseInt(data.unread_count, 10);
              var $countContainer = $('#global_nav_conversations_link').find('.menu-item__badge');
              $countContainer.text(parsedInt);
              $countContainer.toggle(parsedInt > 0);
            },
            error: (data) => {
              // Failure case, should never get here.
              console.log(data);
            }
          });
        };
        setInterval(updateCount, 30000); // 30 seconds
        updateCount();
      }
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
      this.setState({activeItem});
    },

    handleMenuClick (type) {
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

    render () {
      return (
          <Tray isOpen={this.state.isTrayOpen} onBlur={this.closeTray} closeTimeoutMS={400}>
            {this.renderTrayContent()}
          </Tray>
      );
    }
  });

  return Navigation;
});
