/** @jsx React.DOM */

define(['underscore', 'Backbone'], function(_){

  class ModerationStore {
    constructor () {
      this.events = _.extend({}, Backbone.Events);
      this.submissions = [];
    }

    /**
     * Adds a handler to be fired when the change event occurs.
     * @param {Function} handler Function to be called when the event is fired
     */
    addChangeListener (handler) {
      this.events.on('change', handler);
    }

    /**
     * Removes a handler from the store.
     * @param  {Function} handler Function to be called when the event is fired
     */
    removeChangeListener (handler) {
      this.events.off('change', handler);
    }

    /**
     * Add submissions to the store
     *
     * @param {Array} submission An array of submission objects
     */
    addSubmissions (submissions) {
      this.submissions = this._mergeArraysById(this.submissions, submissions);
      this.events.trigger('change');
    }

    _mergeArraysById (arrayOne, arrayTwo) {
      return _.map(arrayTwo, (item) => {
        var foundItem = _.find(arrayOne, (arrayOneItem) => {
          return arrayOneItem.id === item.id;
        });
        return _.extend(item, foundItem);
      });
    }
  }

  return ModerationStore;
});
