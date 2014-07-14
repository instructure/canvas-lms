define(
  ["./adapters/base","./serializers/base","./models/course","./adapters/course","./serializers/course","./models/module","./adapters/module","./serializers/module","./models/module-item","./serializers/module-item","./adapters/module-item","./models/file","./serializers/file","./adapters/file","./models/folder","./serializers/folder","./adapters/folder","./parse-link-header","ember-data","ember","exports"],
  function(__dependency1__, __dependency2__, __dependency3__, __dependency4__, __dependency5__, __dependency6__, __dependency7__, __dependency8__, __dependency9__, __dependency10__, __dependency11__, __dependency12__, __dependency13__, __dependency14__, __dependency15__, __dependency16__, __dependency17__, __dependency18__, __dependency19__, __dependency20__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;
    var BaseSerializer = __dependency2__["default"] || __dependency2__;

    var Course = __dependency3__["default"] || __dependency3__;
    var CourseAdapter = __dependency4__["default"] || __dependency4__;
    var CourseSerializer = __dependency5__["default"] || __dependency5__;

    var Module = __dependency6__["default"] || __dependency6__;
    var ModuleAdapter = __dependency7__["default"] || __dependency7__;
    var ModuleSerializer = __dependency8__["default"] || __dependency8__;

    var ModuleItem = __dependency9__["default"] || __dependency9__;
    var ModuleItemSerializer = __dependency10__["default"] || __dependency10__;
    var ModuleItemAdapter = __dependency11__["default"] || __dependency11__;

    var File = __dependency12__["default"] || __dependency12__;
    var FileSerializer = __dependency13__["default"] || __dependency13__;
    var FileAdapter = __dependency14__["default"] || __dependency14__;

    var Folder = __dependency15__["default"] || __dependency15__;
    var FolderSerializer = __dependency16__["default"] || __dependency16__;
    var FolderAdapter = __dependency17__["default"] || __dependency17__;

    var parseLinkHeader = __dependency18__["default"] || __dependency18__;
    var DS = __dependency19__["default"] || __dependency19__;
    var Ember = __dependency20__["default"] || __dependency20__;
    var get = Ember.get;

    DS.Store.reopen({
      find: function (type, id, context){
        if(context){
          var record = this.recordForId(type, id);
          record.set('courseIdProperty', context.courseId);
          record.set('moduleIdProperty', context.moduleId);
          record.set('fullNameProperty', context.fullName);
          record.set('isRoot', context.isRoot);
        }

        if(id){
          return this._super(type,id);
        } else {
          return this._super(type);
        }
      },

    });

    DS.ManyArray.reopen({
      getNextPage: function(){
        var store = get(this, 'store');
        var  type = get(this, 'type');
        var meta = this.get('meta');
        var record = this.get('owner');
        var adapter = store.adapterFor(record.constructor);
        var serializer = store.serializerFor(type);
        var hasMany = this;
        var relationship = record._relationships[this.name];
        if (!meta || !meta.next){
          return Ember.RSVP.resolve(null);
        }

        var link = meta.next;
        var promise = adapter.findHasMany(store, record, link, relationship);
        return promise.then(function(adapterPayload){
          var payload = serializer.extract(store, type, adapterPayload, null, 'findHasMany');
          var records = store.pushMany(type, payload);
          hasMany.set('meta', Ember.copy(store.metadataFor(type)));
          hasMany.addObjects(records);
          return hasMany;
        });
      }
    });


    DS.AdapterPopulatedRecordArray.reopen({
      load: function(data) {
        var store = get(this, 'store'),
            type = get(this, 'type'),
            records = store.pushMany(type, data),
            meta = store.metadataFor(type);

        this.setProperties({
          content: Ember.A(records),
          isLoaded: true,
          meta: Ember.copy(meta)
        });

        // TODO: should triggering didLoad event be the last action of the runLoop?
        Ember.run.once(this, 'trigger', 'didLoad');
      }
    });

    __exports__.BaseAdapter = BaseAdapter;
    __exports__.BaseSerializer = BaseSerializer;
    __exports__.Course = Course;
    __exports__.CourseAdapter = CourseAdapter;
    __exports__.CourseSerializer = CourseSerializer;
    __exports__.Module = Module;
    __exports__.ModuleAdapter = ModuleAdapter;
    __exports__.ModuleSerializer = ModuleSerializer;
    __exports__.ModuleItem = ModuleItem;
    __exports__.ModuleItemSerializer = ModuleItemSerializer;
    __exports__.ModuleItemAdapter = ModuleItemAdapter;
    __exports__.File = File;
    __exports__.FileSerializer = FileSerializer;
    __exports__.FileAdapter = FileAdapter;
    __exports__.Folder = Folder;
    __exports__.FolderSerializer = FolderSerializer;
    __exports__.FolderAdapter = FolderAdapter;
    __exports__.parseLinkHeader = parseLinkHeader;
  });