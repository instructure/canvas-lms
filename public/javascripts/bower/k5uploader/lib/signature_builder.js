define(['./md5'], function(MD5){

  return function (params) {
    var names = [];
    for (prop in params) {
      names.push(prop);
    }
    names = names.sort();
    var s = '';
    names.forEach(function(element){
      s += element;
      s += params[element];
    });
    return MD5.encrypt(s);
  }

});
