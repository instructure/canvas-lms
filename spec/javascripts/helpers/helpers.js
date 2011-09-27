function simulateClick (element){
  if (!document.createEvent){
    element.click(); // IE
    return;
  }

  var e = document.createEvent("MouseEvents");
  e.initEvent("click", true, true);
  element.dispatchEvent(e);
}
