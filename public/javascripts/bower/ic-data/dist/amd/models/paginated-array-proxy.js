define(
  ["ember","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var ArrayProxy = __dependency1__.ArrayProxy;
    var RSVP = __dependency1__.RSVP;

    var PaginatedArrayProxy = ArrayProxy.extend({

      files: Ember.computed.alias('folder.files'),
      folders: Ember.computed.alias('folder.folders'),
      files_count: Ember.computed.alias('folder.files_count'),
      folders_count: Ember.computed.alias('folder.folders_count'),
      sortParam: 'name',
      sortOrder: 'asc',
      folder: null,

      content:function(){
        if(this.get('folders.isFulfilled') && this.get('files.isFulfilled')){
          return this.get('folders').toArray().concat(this.get('files').toArray())
        }
        return [];
      }.property('folders.[]', 'files.[]'),

      getNextPage: function(){
        var filesPromise = null;
        var foldersPromise = null;

        if (!this.get('areAllFilesLoaded')){
          filesPromise = this.get('files').then(function(files){
            return files.getNextPage();
          });
        }

        if (!this.get('areAllFoldersLoaded')){
          foldersPromise = this.get('folders').then(function(folders){
            return folders.getNextPage();
          });
        }

        return RSVP.all([filesPromise, foldersPromise]);
      },

      areAllFilesLoaded: function(){
        return this.get('files.length') == this.get('files_count');
      }.property('files.length', 'files_count'),

      areAllFoldersLoaded: function(){
        return this.get('folders.length') == this.get('folders_count');
      }.property('folders.length', 'folders_count'),

      isEverythingLoaded: Ember.computed.and('areAllFoldersLoaded', 'areAllFilesLoaded'),

      setSort: function(column, order){
        this.set('sortParam', column);
        this.set('sortOrder', order);
        if(this.get('isEverythingLoaded')){
           return Ember.RSVP.resolve();
        }
        var folder = this.get('folder');
        folder.data.links.folders = folder.data.links.folders+'?sort=' + column;

        folder.data.links.files = folder.data.links.files+'?sort=' + column;

        folder._relationships.files = null;
        folder._relationships.folders = null;

        folder.notifyPropertyChange('files');
        folder.notifyPropertyChange('folders');
        return RSVP.all([this.get('folder.files'), this.get('folder.folders')])

      }

    });


    __exports__["default"] = PaginatedArrayProxy;
  });