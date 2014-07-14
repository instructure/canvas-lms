define("ic-data/adapters/base",
  ["ember-data","../parse-link-header","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var RESTAdapter = __dependency1__.RESTAdapter;
    var parseLinkHeader = __dependency2__["default"] || __dependency2__;

    __exports__["default"] = RESTAdapter.extend({
      namespace: '/api/v1',
      ajax: function(url, type, hash) {
        var adapter = this;

        return new Ember.RSVP.Promise(function(resolve, reject) {
          hash = adapter.ajaxOptions(url, type, hash);

          hash.success = function(json, status, hxr) {
            json.meta = parseLinkHeader(hxr);
            Ember.run(null, resolve, json);
          };

          hash.error = function(jqXHR, textStatus, errorThrown) {
            Ember.run(null, reject, adapter.ajaxError(jqXHR));
          };

          Ember.$.ajax(hash);
        }, "DS: RestAdapter#ajax " + type + " to " + url);
      }
    });
  });
define("ic-data/adapters/course",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;

    var CourseAdapter = BaseAdapter.extend({
      createRecord: function(store, type, record) {
        var data = {};
        var serializer = store.serializerFor(type.typeKey);
        var url = this.urlPrefix()+'/accounts/'+record.get('account_id')+'/courses';
        record.set('account_id', null);
        serializer.serializeIntoHash(data, type, record, { includeId: true });
        return this.ajax(url, "POST", { data: data });
      },

      deleteRecord: function(store, type, record) {
        var id = record.get('id');
        var data = { event: 'delete' };
        return this.ajax(this.buildURL(type.typeKey, id), "DELETE", {data: data});
      }
    });

    __exports__["default"] = CourseAdapter;
  });
define("ic-data/adapters/file",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;

    var FileAdapter = BaseAdapter.extend({
      createRecord: function(store, type, record) {
        var data = {};
        var serializer = store.serializerFor(type.typeKey);
        var url = this.urlPrefix()+'/accounts/'+record.get('account_id')+'/courses';
        record.set('account_id', null);
        serializer.serializeIntoHash(data, type, record, { includeId: true });
        return this.ajax(url, "POST", { data: data });
      },

      deleteRecord: function(store, type, record) {
        var id = record.get('id');
        var data = { event: 'delete' };
        return this.ajax(this.buildURL(type.typeKey, id), "DELETE", {data: data});
      }
    });

    __exports__["default"] = FileAdapter;
  });
define("ic-data/adapters/folder",
  ["./base","ember","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;
    var String = __dependency2__.String;

    var FolderAdapter = BaseAdapter.extend({
      findQuery: function(store, type, query){
        var contextType = query.contextType,
            contextId = query.contextId,
            fullName = query.fullName,
            url = this.buildURL(type.typeKey);

        delete query.contextType;
        delete query.contextId;
        delete query.fullName;

        if (fullName != null) { // use by_path even if full_name is ''
          url = [
            this.urlPrefix(),
            String.pluralize(contextType),
            contextId,
            'folders/by_path',
            encodeURI(fullName)
          ].join('/');
        }

        return this.ajax(url, 'GET', query).then(function(folders){
          if (!Array.isArray(folders)) folders = [folders];
          return folders;
        });
      },


     find: function(store, type, id) {

        var record = store.getById(type, id);
        if(!record.get('courseIdProperty')){
          return this._super(store,type,id);
        }
        var url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/folders/'+record.get('id');
        if (record.get('isRoot')){
          url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/folders/root';
        } else if (record.get('fullNameProperty')){
        }
        var courseId = record.get('courseIdProperty');
        return this.ajax(url, "GET").then( function(folders){
          if (!Array.isArray(folders)) {
            folders.course_id = courseId;
            return folders;
          }

          folders.forEach( function(folder){
            folders.course_id = courseId;
          });
          return folders;
        });
      },
      /*
      createRecord: function(store, type, record) {
        var data = {};
        var serializer = store.serializerFor(type.typeKey);
        var url = this.urlPrefix()+'/accounts/'+record.get('account_id')+'/courses';
        record.set('account_id', null);
        serializer.serializeIntoHash(data, type, record, { includeId: true });
        return this.ajax(url, "POST", { data: data });
      },

      deleteRecord: function(store, type, record) {
        var id = record.get('id');
        var data = { event: 'delete' };
        return this.ajax(this.buildURL(type.typeKey, id), "DELETE", {data: data});
      }
      */
    });

    __exports__["default"] = FolderAdapter;
  });
define("ic-data/adapters/module-item",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;

    var ModuleItemAdapter = BaseAdapter.extend({
      findQuery: function(store, type, query){
        var url = this.urlPrefix()+'/courses/' + query.courseId + '/modules/'+query.moduleId+'/items';
        var moduleId = query.moduleId;
        delete query.moduleId;
        var courseId = query.courseId;
        delete query.courseId;
        var params = {data: query};
        if (query.url){
          params = null;
          url = query.url;
          //TODO Makes this reasonable
          url = url.replace("https://localhost", "http://localhost:8080");
        }
        return this.ajax(url, 'GET', params).then( function(modules){
          modules.forEach( function(module){
            module.module_id = moduleId;
            module.course_id = courseId;
          });
          return modules;
        });
      }
    });

    __exports__["default"] = ModuleItemAdapter;
  });
define("ic-data/adapters/module",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;

    var ModuleAdapter =  BaseAdapter.extend({
      createRecord: function(store, type, record) {
        var data = {};
        var serializer = store.serializerFor(type.typeKey);
        var url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/modules';
        serializer.serializeIntoHash(data, type, record, { includeId: true });
        return this.ajax(url, "POST", { data: data });
      },

      deleteRecord: function(store, type, record) {
        var url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/modules/'+record.get('id');
        return this.ajax(url, "DELETE");
      },

     find: function(store, type, id) {
        var record = store.getById(type, id);
        var url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/modules/'+record.get('id');
        var courseId = record.get('courseIdProperty');
        return this.ajax(url, "GET").then( function(modules){
          if (!Array.isArray(modules)) {
            modules.course_id = courseId;
            return modules;
          }

          modules.forEach( function(module){
            module.course_id = courseId;
          });
          return modules;
        });
      },

      findQuery: function(store, type, query){
        var url = this.urlPrefix()+'/courses/'+query.courseId+'/modules';
        if (query.id){
          url = url + '/' + query.id;
          delete query.id;
        }
        var courseId = query.courseId;
        delete query.courseId;
        var params = {data: query};
        if (query.url){
          params = null;
          url = query.url;
          //TODO Makes this reasonable
          url = url.replace("https://localhost", "http://localhost:8080");
        }
        return this.ajax(url, 'GET', params).then( function(modules){
          if (!Array.isArray(modules)) {
            modules.course_id = courseId;
            return modules;
          }

          modules.forEach( function(module){
            module.course_id = courseId;
          });
          return modules;
        });
      }
    });

    __exports__["default"] = ModuleAdapter;
  });
define("ic-data",
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
define("ic-data/models/course",
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;

    var Course = Model.extend({
      name: attr(),

      folder: DS.belongsTo('folder', {async:true}),
      conclude: function() {
        // DELETE to url with {event: 'conclude'}
        // TODO: how?
        //this.destroyRecord({event: 'conclude'});
      }
    });

    __exports__["default"] = Course;
  });
define("ic-data/models/file",
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;
    var belongsTo = __dependency1__.belongsTo;

    var File = Model.extend({

      folder: belongsTo('folder'),

      user: attr(),//belongsTo('user', {embedded: 'always'}),

      size: attr('number'),

      'content-type': attr('number'),

      url: attr('string'),

      display_name: attr('string'),

      // used so ChildrenController can sort by 'name'
      name: Ember.computed.alias('display_name'),

      created_at: attr('date'),

      updated_at: attr('date'),

      lock_at: attr('date'),

      unlock_at: attr('date'),

      hidden: attr('boolean'),

      hidden_for_user: attr('boolean'),

      locked: attr('boolean'),

      locked_for_user: attr('boolean'),

      lock_info: attr('string'),

      lock_explanation: attr('string'),

      thumbnail_url: attr('string')


    });

    __exports__["default"] = File;
  });
define("ic-data/models/folder",
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
define("ic-data/models/module-item",
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Model = __dependency1__.Model;
    var attr = __dependency1__.attr;

    var ModuleItem = Model.extend({
      title: attr(),

      // need this to do anything
      moduleId: attr(),

      //TODO HACKS, FIX
      //Add merging support to adapterDidCommit
      moduleIdProperty: function(key, value){
        if (value) {
          this.set('moduleIdCache', value);
          return value;
       }
        var id = this.get('moduleId');
        if (id){
          this.set('moduleIdCache', id);
          return id;
        }
        return this.get('moduleIdCache');
      },

      // need this to do anything
      courseId: attr(),

      //TODO HACKS, FIX
      //Add merging support to adapterDidCommit
      courseIdProperty: function(key, value){
        if (value) {
          this.set('courseIdCache', value);
          return value;
       }
        var id = this.get('courseId');
        if (id){
          this.set('courseIdCache', id);
          return id;
        }
        return this.get('courseIdCache');
      }.property('courseId')

    });
    __exports__["default"] = ModuleItem;
  });
define("ic-data/models/module",
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
define("ic-data/models/paginated-array-proxy",
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
define("ic-data/parse-link-header",
  ["exports"],
  function(__exports__) {
    "use strict";
    function parseLinkHeader(xhr) {
      var regex = /<(http.*?)>; rel="([a-z]*)",?/g;
      var links = {};
      var header = xhr.getResponseHeader('Link');
      if (!header) {
        header = xhr.getResponseHeader('link');
        if (!header) {
          return links;
        }
      }
      var link;
      while (link = regex.exec(header)) {
        links[link[2]] = link[1];
      }
      return links;
    }

    __exports__["default"] = parseLinkHeader;
  });
define("ic-data/serializers/base",
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var RESTSerializer = __dependency1__.RESTSerializer;

    var BaseSerializer =  RESTSerializer.extend({
      normalizePayload: function(primaryType, payload){
        var data = {};
        if (Array.isArray(payload)) {
          data[primaryType.typeKey+'s'] = payload;
        } else {
          data[primaryType.typeKey] = payload;
        }
        return data;
      },

      extractMeta: function(store, type, payload){
        if(payload.meta && payload.meta.next){
          payload.meta.next = payload.meta.next.replace("https://localhost", "http://localhost:8080");
        }
        this._super(store, type, payload);
      }
    });

    __exports__["default"] = BaseSerializer;
  });
define("ic-data/serializers/course",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var CourseSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      },
      normalize: function(type, hash, prop){
        hash.links = hash.links || {};
        var store = type.store;
        var adapter = store.adapterFor(type);
        hash.links.folder = adapter.urlPrefix() + '/courses/' + hash.id + '/folders/root';
        return this._super(type, hash, prop);
      }
    });

    __exports__["default"] = CourseSerializer;
  });
define("ic-data/serializers/file",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var FileSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      }
    });

    __exports__["default"] = FileSerializer;
  });
define("ic-data/serializers/folder",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var FolderSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      },
      normalize: function(type, hash, prop){
        hash.links = hash.links || {};
        ['files', 'folders'].forEach(function(linkType){
          var url = hash[linkType + '_url'] + '?include[]=user';
          url = url.replace("https://localhost", "http://localhost:8080"); // TODO remove
          hash.links[linkType] = url;
          delete hash[linkType + '_url']
        })
        return this._super(type, hash, prop);
      },

      keyForRelationship: function(key, kind){
        if (kind === "belongsTo") {
          return key + "_id";
        } else {
          return key;
        }
      }

    });

    __exports__["default"] = FolderSerializer;
  });
define("ic-data/serializers/module-item",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var ModuleItemSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      }
    });

    __exports__["default"] = ModuleItemSerializer;
  });
define("ic-data/serializers/module",
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var ModuleSerializer = BaseSerializer.extend({
      normalize: function(type, hash, prop){
        hash.links = hash.links || {};
        var url = hash.items_url;
        url = url.replace("https://localhost", "http://localhost:8080");
        hash.links.items = url;
        delete hash.items_url;
        return this._super(type, hash, prop);
      },

    });

    __exports__["default"] = ModuleSerializer;
  });