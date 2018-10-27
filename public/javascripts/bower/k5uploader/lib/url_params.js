export default function (params) {
  var queryUrl = '?';
  for(var prop in params){
    queryUrl += prop + '=' + encodeURIComponent(params[prop]) + '&';
  }
  queryUrl = queryUrl.substring(0, queryUrl.length - 1);
  return queryUrl;
};
