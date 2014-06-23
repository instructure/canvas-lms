define([], function(){

  function isPresent(passed, name) {
    return (passed && passed[name] !== undefined)
  }

  return function(name, options, passed){
    if (isPresent(passed, name)) {
      options[name] = passed[name]
    }
   }

});
