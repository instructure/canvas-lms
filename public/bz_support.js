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
    1. canvas loads
    2. this file loads, making the function available
    3. Canvas coffeecript runs, which can call this function
    4. bz_custom.js runs
    5. bottom scripts in view html run, which can also call thi
*/
function bzRetainedInfoSetup() {
  function bzChangeRetainedItem(ta, value) {
    if(ta.tagName == "INPUT" && ta.getAttribute("type") == "checkbox")
      ta.checked = (value == "yes") ? true : false;
    else if(ta.tagName == "INPUT" && ta.getAttribute("type") == "radio")
      ta.checked = (value == ta.value) ? true : false;
    else if(ta.tagName == "INPUT" || ta.tagName == "TEXTAREA")
      ta.value = value;
    else
      ta.textContent = value;
  }

  var names = document.querySelectorAll(".bz-user-name");
  for(var i = 0; i < names.length; i++) {
    var element = names[i];
    element.className = "bz-user-name-showing";
    element.textContent = ENV.current_user.display_name;
  }

  var textareas = document.querySelectorAll("[data-bz-retained]");
  for(var i = 0; i < textareas.length; i++) {
    (function(ta) {
      var name = ta.getAttribute("data-bz-retained");

      if(ta.className.indexOf("bz-retained-field-setup") != -1)
        return; // already set up, no need to redo

      if(ta.tagName == "IMG") {
        // this is a hack so the editor will not allow text inside:
        // the field pretends to be an image in that context. But, when
        // it is time to display it, we want to switch back to being an
        // ordinary span.
        var span = document.createElement("span");
        span.className = ta.className;
        span.setAttribute("data-bz-retained", ta.getAttribute("data-bz-retained"));
        ta.parentNode.replaceChild(span, ta);
        ta = span;
      }

      var save = function() {
        var http = new XMLHttpRequest();
        http.open("POST", "/bz/user_retained_data", true);
        var value = ta.value;
        if(ta.getAttribute("type") == "radio")
          if(!ta.checked)
            return; // we only want to actually save the one that is checked
        if(ta.getAttribute("type") == "checkbox")
          value = ta.checked ? "yes" : "";
        var data = "name=" + encodeURIComponent(name) + "&value=" + encodeURIComponent(value);
        http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        http.send(data);

        // we also need to update other views on the same page
        var textareas = document.querySelectorAll("[data-bz-retained]");
        for(var idx = 0; idx < textareas.length; idx++) {
            var item = textareas[idx];
            if(item == ta)
              continue;
            if(item.getAttribute("data-bz-retained") == name)
              bzChangeRetainedItem(item, value);
        }
      };

      ta.className += " bz-retained-field-setup";
      ta.addEventListener("change", save);

      var http = new XMLHttpRequest();
      // cut off json p stuff
      http.onload = function() { bzChangeRetainedItem(ta, http.responseText.substring(9)); };
      http.open("GET", "/bz/user_retained_data?name=" + encodeURIComponent(name), true);
      http.send();
    })(textareas[i]);
  }
}

if(window != window.top) {
  // we are in an iframe... strip off magic
  document.getElementsByTagName("html")[0].className += " bz-in-iframe";
}
