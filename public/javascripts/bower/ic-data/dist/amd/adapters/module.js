define(
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