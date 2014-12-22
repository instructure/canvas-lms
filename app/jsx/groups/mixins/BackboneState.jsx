/** @jsx React.DOM */

define([
  'underscore',
  'Backbone'
], (_, Backbone) => {
  var BackboneState = {
    _forceUpdate() {this.forceUpdate()}, // strips off args that backbone sends and react incorrectly believes is a callback

    _on(object, name, callback, context) {
      object.on(name, callback, context);
    },

    _off(object, name, callback, context) {
      object.off(name, callback, context);
    },

    _listen(func, state, exceptState) {
      for (var stateKey in state) {
        if (state.hasOwnProperty(stateKey)) {
          if (!(exceptState && exceptState.hasOwnProperty(stateKey) && state[stateKey] === exceptState[stateKey])) {
            var stateObject = state[stateKey];
            if (stateObject instanceof Backbone.Collection) {
              func(stateObject, 'add remove reset sort fetch beforeFetch change', this._forceUpdate, this);
            } else if (stateObject instanceof Backbone.Model) {
              func(stateObject, 'change', this._forceUpdate,  this);
            }
          }
        }
      }
    },

    componentWillUpdate(nextProps, nextState) {
      // stop listening to backbone objects in state that aren't in nextState
      this._listen(this._off, this.state, nextState);
    },

    componentDidUpdate(prevProps, prevState) {
      // start listening to backbone objects in state that aren't in prevState
      this._listen(this._on, this.state, prevState);
    },

    componentDidMount() {
      // start listening to backbone objects in state
      this._listen(this._on, this.state);
    },

    componentWillUnmount() {
      // stop listening to backbone objects in state
      this._listen(this._off, this.state);
    }
  };
  return BackboneState;
});
