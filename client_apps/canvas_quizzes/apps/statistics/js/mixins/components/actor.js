define((require) => {
  const Dispatcher = require('../../core/dispatcher');

  /**
   * @class Statistics.Mixins.Components.ActorMixin
   *
   * Extend a component with the ability to dispatch (and track) events to
   * stores directly using a `#sendAction()` helper.
   */
  const ActorMixin = {
    getInitialState () {
      return {
        actionIndex: null
      };
    },

    getDefaultProps () {
      return {
        storeError: null
      };
    },

    componentWillReceiveProps (nextProps) {
      const storeError = nextProps.storeError;

      if (storeError && storeError.actionIndex === this.state.actionIndex) {
        this.setState({ storeError });
      }
    },

    componentDidUpdate () {
      if (this.state.storeError) {
        if (this.onStoreError) {
          this.onStoreError(this.state.storeError);
        }

        // Consume it so that the handling code doesn't get called repeatedly.
        this.setState({ storeError: null });
      }
    },

    componentWillUnmount () {
      this.lastAction = undefined;
    },

    /**
     * Convenient method for consuming events.
     *
     * @param {Event} e
     *        Something that responds to #preventDefault().
     */
    consume (e) {
      if (e) {
        e.preventDefault();
      }
    },

    /**
     * Send an action via the Dispatcher, track the action promise, and any
     * error the handler raises.
     *
     * A reference to the action handler's promise will be kept in
     * `this.lastAction`. The index of the action is tracked in
     * this.state.actionIndex.
     *
     * If an error is raised, it will be accessible in `this.state.storeError`.
     *
     * @param {String} action (required)
     *        Unique action identifier. Must be scoped by the store key, e.g:
     *        "categories:save", or "users:changePassword".
     *
     * @param {Object} [params={}]
     *        Action payload.
     *
     * @param {Object} [options={}]
     * @param {Boolean} [options.track=true]
     *        Pass as false if you don't want the mixin to perform any tracking.
     *
     * @return {RSVP.Promise}
     *         The action promise which will fulfill if the action succeeds,
     *         or fail if the action doesn't. Failure will be presented by
     *         an error that adheres to the UIError interface.
     */
    sendAction (action, params, options) {
      let service;
      let setState;

      service = Dispatcher.dispatch(action, params);

      if (options && options.track === false) {
        return;
      }

      setState = this.setState.bind(this);
      this.lastAction = service.promise;

      setState({
        actionIndex: service.index
      });

      service.promise.then(null, (error) => {
        setState({
          storeError: {
            actionIndex: service.index,
            error
          }
        });
      });

      return service.promise;
    }
  };

  return ActorMixin;
});
