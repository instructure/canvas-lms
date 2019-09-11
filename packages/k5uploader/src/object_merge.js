export default function(objs) {
  if (!objs) {
    return objs
  }
  var combined = {};
  objs = objs.reverse();
  objs.forEach(obj => {
    for(var prop in obj) {
      combined[prop] = obj[prop]
    }
  });
  return combined;
};
