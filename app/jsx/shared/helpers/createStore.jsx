/** @jsx */
define(['underscore', 'Backbone'], function(_, Backbone) {

  /**
   * Creates a data store with some initial state.
   *
   * ```js
   * var UserStore = createStore({loaded: false, users: []});
   *
   * UserStore.load = function() {
   *   $.getJSON('/users', function(users) {
   *     UserStore.setState({loaded: true, users});
   *   });
   * };
   * ```
   *
   * Then in a component:
   *
   * ```js
   * var UsersView = React.createClass({
   *   getInitialState () {
   *     return UserStore.getState();
   *   },
   *
   *   componentDidMount () {
   *     UserStore.addChangeListener(this.handleStoreChange);
   *     UserStore.load();
   *   },
   *
   *   handleStoreChange () {
   *     this.setState(UserStore.getState());
   *   }
   * });
   * ```
   */

  function createStore(initialState) {
    var events = _.extend({}, Backbone.Events);
    var state = initialState || {};

    return {
      setState (newState) {
        _.extend(state, newState);
        this.emitChange();
      },

      getState () {
        return state;
      },

      addChangeListener  (listener) {
        events.on('change', listener);
      },

      removeChangeListener  (listener) {
        events.off('change', listener);
      },

      emitChange () {
        events.trigger('change');
      }

    };
  };

  return createStore;
});

