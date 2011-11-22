define('helpers/simulateClick', ['vendor/jquery-1.6.4'], function(_){
  return function(element){
    if (!document.createEvent){
      element.click(); // IE
      return;
    }

    var e = document.createEvent("MouseEvents");
    e.initEvent("click", true, true);
    element.dispatchEvent(e);
  }
});

