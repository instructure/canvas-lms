/** @jsx React.DOM */

define(['underscore', 'Backbone'], function(_){

  class ModerationStore {
    constructor () {
      this.events = _.extend({}, Backbone.Events);
      this.students = [];
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
     * Add students to the store
     *
     * @param {Array} students An array of student objects
     */
    addStudents (students) {
      this.students = this._mergeArraysById(this.students, students);
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
