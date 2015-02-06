/** @jsx */

define([
  './ObjectStore'
], function(ObjectStore) {

  class FolderStore extends ObjectStore {
    /**
     * contextAndId should be in the format 'context/id'
     */
    constructor(contextAndId) {
      var apiUrl = '/api/v1/' + contextAndId + '/folders?per_page=20';
      super(apiUrl);
    }
  }

  return FolderStore;
});