define(function() {
  return function wrap(value) {
    return Array.isArray(value) ?
      value :
      value === undefined ?
        [] :
        [ value ];
  };
});