define([], function(){

  return function (params) {
    queryUrl = '?';
    for(prop in params){
      queryUrl += prop + '=' + encodeURIComponent(params[prop]) + '&';
    }
    queryUrl = queryUrl.substring(0, queryUrl.length - 1);
    return queryUrl;
  }

});
