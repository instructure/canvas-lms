define(
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