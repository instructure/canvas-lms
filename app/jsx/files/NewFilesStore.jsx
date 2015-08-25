/** @jsx React.DOM */

define(['underscore', 'Backbone'], function(_, Backbone) {

  class NewFilesStore {

    constructor () {
      this.events = _.extend({}, Backbone.Events);
      this.folders = [];
      this.files = [];
    }

    /**
     * Adds folders to the store, emits an onChange event from the store.
     * The folders are 'smartly' merged by id.  This basically results in the
     * only adding folders that aren't already in the store.
     *
     * @param {Array} folders An array of folder objects
     */
    addFolders (folders) {
      this.folders = this._mergeArraysById(this.folders, folders);
      this.events.trigger('change');
    }

    /**
     * Adds files to the store, emits an onChange event from the store.
     * The files are 'smartly' merged by id.  This basically results in the
     * only adding files that aren't already in the store.
     *
     * @param {Array} files An array of file objects
     */
    addFiles (files) {
      this.files = this._mergeArraysById(this.files, files);
      this.events.trigger('change');
    }

    /**
     * Removes a list of folders from the store
     * @param  {Array} folders
     */
    removeFolders (folders) {
      this.folders = this._removeFromStore(this.folders, folders);
      this.events.trigger('change');
    }

    /**
     * Removes a list of files from the store
     * @param  {Array} files
     */
    removeFiles (files) {
      this.files = this._removeFromStore(this.files, files);
      this.events.trigger('change');
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

    _mergeArraysById (arrayOne, arrayTwo) {
      return _.map(arrayTwo, (item) => {
        var foundItem = _.find(arrayOne, (arrayOneItem) => {
          return arrayOneItem.id === item.id;
        });
        return _.extend(item, foundItem);
      });
    }

    _removeFromStore(store, itemsToRemove) {
      return _.reject(store, (item) => {
        return _.find(itemsToRemove, (it) => {
          return it.id === item.id;
        });
      });
    }
  }

  return NewFilesStore;

});