/********************
  The purpose of this file is to hold functions we need from Canvas
  controllers that cannot be put in bz_custom.js due to order-of-load
  dependencies.
********************/

/*
  This function is responsible for loading and setting event handlers
  for the magic fields (retained data feature) used in the WYSIWYG
  editor.

  It is called by Canvas on its after render event, which happens AFTER
  window.onload, but BEFORE bz_custom.js is loaded - meaning this function
  needs to be available separately.

  Flow:
    -> canvas loads
*/
function bzRetainedInfoSetup() {
alert("ru nning");
  var textareas = document.querySelectorAll("[data-bz-retained]");
  for(var i = 0; i < textareas.length; i++) {
    (function(ta) {
      var name = ta.getAttribute("data-bz-retained");

      if(ta.className.indexOf("bz-retained-field-setup") != -1)
        return; // already set up, no need to redo

      var save = function() {
        var http = new XMLHttpRequest();
        http.open("POST", "/bz/user_retained_data", true);
        var data = "name=" + encodeURIComponent(name) + "&value=" + encodeURIComponent(ta.value);
        http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        http.send(data);
      };

      ta.className += " bz-retained-field-setup";
      ta.addEventListener("change", save);

      var http = new XMLHttpRequest();
      http.onload = function() {
          // cut off json p stuff
          if(ta.tagName == "SPAN")
            ta.textContent = http.responseText.substring(9);
          else
            ta.value = http.responseText.substring(9);
      };
      http.open("GET", "/bz/user_retained_data?name=" + encodeURIComponent(name), true);
      http.send();
    })(textareas[i]);
  }
}

