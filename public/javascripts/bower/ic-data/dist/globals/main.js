!function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),(f.ic||(f.ic={})).data=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
"use strict";
var RESTAdapter = window.DS.RESTAdapter;
var parseLinkHeader = _dereq_("../parse-link-header")["default"] || _dereq_("../parse-link-header");

exports["default"] = RESTAdapter.extend({
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
},{"../parse-link-header":14}],2:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = CourseAdapter;
},{"./base":1}],3:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = FileAdapter;
},{"./base":1}],4:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./base")["default"] || _dereq_("./base");
var String = window.Ember.String;

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

exports["default"] = FolderAdapter;
},{"./base":1}],5:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = ModuleItemAdapter;
},{"./base":1}],6:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = ModuleAdapter;
},{"./base":1}],7:[function(_dereq_,module,exports){
"use strict";
var BaseAdapter = _dereq_("./adapters/base")["default"] || _dereq_("./adapters/base");
var BaseSerializer = _dereq_("./serializers/base")["default"] || _dereq_("./serializers/base");

var Course = _dereq_("./models/course")["default"] || _dereq_("./models/course");
var CourseAdapter = _dereq_("./adapters/course")["default"] || _dereq_("./adapters/course");
var CourseSerializer = _dereq_("./serializers/course")["default"] || _dereq_("./serializers/course");

var Module = _dereq_("./models/module")["default"] || _dereq_("./models/module");
var ModuleAdapter = _dereq_("./adapters/module")["default"] || _dereq_("./adapters/module");
var ModuleSerializer = _dereq_("./serializers/module")["default"] || _dereq_("./serializers/module");

var ModuleItem = _dereq_("./models/module-item")["default"] || _dereq_("./models/module-item");
var ModuleItemSerializer = _dereq_("./serializers/module-item")["default"] || _dereq_("./serializers/module-item");
var ModuleItemAdapter = _dereq_("./adapters/module-item")["default"] || _dereq_("./adapters/module-item");

var File = _dereq_("./models/file")["default"] || _dereq_("./models/file");
var FileSerializer = _dereq_("./serializers/file")["default"] || _dereq_("./serializers/file");
var FileAdapter = _dereq_("./adapters/file")["default"] || _dereq_("./adapters/file");

var Folder = _dereq_("./models/folder")["default"] || _dereq_("./models/folder");
var FolderSerializer = _dereq_("./serializers/folder")["default"] || _dereq_("./serializers/folder");
var FolderAdapter = _dereq_("./adapters/folder")["default"] || _dereq_("./adapters/folder");

var parseLinkHeader = _dereq_("./parse-link-header")["default"] || _dereq_("./parse-link-header");
var DS = window.DS["default"] || window.DS;
var Ember = window.Ember["default"] || window.Ember;
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

exports.BaseAdapter = BaseAdapter;
exports.BaseSerializer = BaseSerializer;
exports.Course = Course;
exports.CourseAdapter = CourseAdapter;
exports.CourseSerializer = CourseSerializer;
exports.Module = Module;
exports.ModuleAdapter = ModuleAdapter;
exports.ModuleSerializer = ModuleSerializer;
exports.ModuleItem = ModuleItem;
exports.ModuleItemSerializer = ModuleItemSerializer;
exports.ModuleItemAdapter = ModuleItemAdapter;
exports.File = File;
exports.FileSerializer = FileSerializer;
exports.FileAdapter = FileAdapter;
exports.Folder = Folder;
exports.FolderSerializer = FolderSerializer;
exports.FolderAdapter = FolderAdapter;
exports.parseLinkHeader = parseLinkHeader;
},{"./adapters/base":1,"./adapters/course":2,"./adapters/file":3,"./adapters/folder":4,"./adapters/module":6,"./adapters/module-item":5,"./models/course":8,"./models/file":9,"./models/folder":10,"./models/module":12,"./models/module-item":11,"./parse-link-header":14,"./serializers/base":15,"./serializers/course":16,"./serializers/file":17,"./serializers/folder":18,"./serializers/module":20,"./serializers/module-item":19}],8:[function(_dereq_,module,exports){
"use strict";
var Model = window.DS.Model;
var attr = window.DS.attr;

var Course = Model.extend({
  name: attr(),

  folder: DS.belongsTo('folder', {async:true}),
  conclude: function() {
    // DELETE to url with {event: 'conclude'}
    // TODO: how?
    //this.destroyRecord({event: 'conclude'});
  }
});

exports["default"] = Course;
},{}],9:[function(_dereq_,module,exports){
"use strict";
var Model = window.DS.Model;
var attr = window.DS.attr;
var belongsTo = window.DS.belongsTo;

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

exports["default"] = File;
},{}],10:[function(_dereq_,module,exports){
"use strict";
var Model = window.DS.Model;
var attr = window.DS.attr;
var hasMany = window.DS.hasMany;
var belongsTo = window.DS.belongsTo;
var ArrayProxy = window.Ember.ArrayProxy;
var copy = window.Ember.copy;
var PaginatedArrayProxy = _dereq_("./paginated-array-proxy")["default"] || _dereq_("./paginated-array-proxy");

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

exports["default"] = Folder;
},{"./paginated-array-proxy":13}],11:[function(_dereq_,module,exports){
"use strict";
var Model = window.DS.Model;
var attr = window.DS.attr;

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
exports["default"] = ModuleItem;
},{}],12:[function(_dereq_,module,exports){
"use strict";
var Model = window.DS.Model;
var attr = window.DS.attr;
var belongsTo = window.DS.belongsTo;
var hasMany = window.DS.hasMany;
var copy = window.Ember.copy;

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

exports["default"] = Module;
},{}],13:[function(_dereq_,module,exports){
"use strict";
var ArrayProxy = window.Ember.ArrayProxy;
var RSVP = window.Ember.RSVP;

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


exports["default"] = PaginatedArrayProxy;
},{}],14:[function(_dereq_,module,exports){
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

exports["default"] = parseLinkHeader;
},{}],15:[function(_dereq_,module,exports){
"use strict";
var RESTSerializer = window.DS.RESTSerializer;

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

exports["default"] = BaseSerializer;
},{}],16:[function(_dereq_,module,exports){
"use strict";
var BaseSerializer = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = CourseSerializer;
},{"./base":15}],17:[function(_dereq_,module,exports){
"use strict";
var BaseSerializer = _dereq_("./base")["default"] || _dereq_("./base");

var FileSerializer = BaseSerializer.extend({
  extractDeleteRecord: function(store, type, payload) {
    // payload is {delete: true} and then ember data wants to go ahead and set
    // the new properties, return null so it doesn't try to do that
    return null;
  }
});

exports["default"] = FileSerializer;
},{"./base":15}],18:[function(_dereq_,module,exports){
"use strict";
var BaseSerializer = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = FolderSerializer;
},{"./base":15}],19:[function(_dereq_,module,exports){
"use strict";
var BaseSerializer = _dereq_("./base")["default"] || _dereq_("./base");

var ModuleItemSerializer = BaseSerializer.extend({
  extractDeleteRecord: function(store, type, payload) {
    // payload is {delete: true} and then ember data wants to go ahead and set
    // the new properties, return null so it doesn't try to do that
    return null;
  }
});

exports["default"] = ModuleItemSerializer;
},{"./base":15}],20:[function(_dereq_,module,exports){
"use strict";
var BaseSerializer = _dereq_("./base")["default"] || _dereq_("./base");

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

exports["default"] = ModuleSerializer;
},{"./base":15}]},{},[7])
(7)
});