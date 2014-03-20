define(
  ["ember-data","ember","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;
    var belongsTo = __dependency1__.belongsTo;
    var hasMany = __dependency1__.hasMany;
    var copy = __dependency2__.copy;

    var Module = Model.extend({

      // need this to do anything
      course_id: attr(),

      items: hasMany('moduleItem', {async:true}),

      //TODO HACKS, FIX
      //Add merging support to adapterDidCommit
      courseIdProperty: function(){
        var id = this.get('course_id');
        if (id){
          this.set('courseIdCache', id);
          return id;
        }
        return this.get('courseIdCache');
      }.property('course_id'),

      name: attr(),

      updateHasMany: function(name, records){
        this._super(name, records);
        var hasMany = this._relationships[name];
        var type = hasMany.get('type');
        hasMany.set('meta', copy(this.store.metadataFor(type)));
      }
    });

    __exports__["default"] = Module;
  });