import MD5 from "./md5";

export default function (params) {
  var names = [];
  for (var prop in params) {
    names.push(prop);
  }
  names = names.sort();
  var s = '';
  names.forEach(function(element){
    s += element;
    s += params[element];
  });
  return MD5.encrypt(s);
};
