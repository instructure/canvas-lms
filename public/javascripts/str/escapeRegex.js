define(function() {
  return function(string) {
    return string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  }
});

