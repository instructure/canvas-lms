define(
  ["ember-data","ember","./paginated-array-proxy","exports"],
  function(__dependency1__, __dependency2__, __dependency3__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;
    var hasMany = __dependency1__.hasMany;
    var belongsTo = __dependency1__.belongsTo;
    var ArrayProxy = __dependency2__.ArrayProxy;
    var copy = __dependency2__.copy;
    var PaginatedArrayProxy = __dependency3__["default"] || __dependency3__;

    var Folder = Model.extend({
      parent_folder: belongsTo('folder', {async:true, inverse:'folders'}),

      folders: hasMany('folder', { async:true, inverse: 'parent_folder' }),

      context_type: attr(),

      context_id: attr(),

      files: hasMany('file', { async: true }),

      children: function(){
        return PaginatedArrayProxy.create({folder:this});

      }.property(),

      files_count: attr(),

      position: attr(),

      folders_url: attr(),

      files_url: attr(),

      full_name: attr(),

      isRoot: null,

      course_id: attr(),

      courseIdProperty: function(){
        var id = this.get('course_id');
        if (id){
          this.set('courseIdCache', id);
          return id;
        }
        return this.get('courseIdCache');
      }.property('course_id'),

      fullNameProperty: function(){
        var id = this.get('full_name');
        if (id){
          this.set('fullNameCache', id);
          return id;
        }
        return this.get('fullNameCache');
      }.property('full_name'),

      folders_count: attr(),

      name: attr(),

      // TODO: take out when things get fixed upstream in ember-data
      updateHasMany: function(name, records){
        this._super(name, records);
        var hasMany = this._relationships[name];
        var type = hasMany.get('type');
        hasMany.set('meta', copy(this.store.metadataFor(type)));
      }

      /*
      TODO uncomment once we figuure out the container isssue
      created_at: attr('date'),

      updated_at: attr('date'),

      lock_at: attr('date'),

      unlock_at: attr('date'),

      hidden: attr('boolean'),

      hidden_for_user: attr('boolean'),

      locked: attr('boolean'),

      locked_for_user: attr('boolean'),
      */

    });

    __exports__["default"] = Folder;
  });