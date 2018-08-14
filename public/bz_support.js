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

var onMagicFieldsLoaded = [];
var magicFieldsLoaded = false;

function addOnMagicFieldsLoaded(func) {
  if(magicFieldsLoaded) {
    console.log("running magic field thing now");
    func();
  } else {
    console.log("queuing magic field thing");
    onMagicFieldsLoaded.push(func);
  }
}

/*
	In the HTML, you can use placeholders {NAME} {ID} and {COURSE_ID}
	inside any .duplicate-for-each-cohort-member element. the innerHTML
	is duplicated for each member.

	Add class `include-all-ta-cohorts-across-courses` to list every one
	the given user is a TA for. (e.g. for LC evals.)
*/
function expandCohortMagicFields(ele) {
	if(!ele)
		ele = document.querySelector("body");

	if(document.getElementById("my-current-cohort-json") == null)
		return;

	var cohort = JSON.parse(document.getElementById("my-current-cohort-json").innerHTML);

	var dupes = ele.querySelectorAll(".duplicate-for-each-cohort-member");
	for(var i = 0; i < dupes.length; i++) {
		var d = dupes[i];
		if(d.classList.contains("already-duplicated"))
			continue;

		var html = d.innerHTML;
		var newHtml = "";

		var replacedHtml;

		for(var id in cohort) {
			var name = cohort[id];
			replacedHtml = html.replace(new RegExp("\\{ID\\}", "g"), id);
			replacedHtml = replacedHtml.replace(new RegExp("\\{COURSE_ID\\}", "g"), ENV["COURSE_ID"]);
			replacedHtml = replacedHtml.replace(new RegExp("\\{NAME\\}", "g"), name);

			newHtml += replacedHtml;
		}

		d.innerHTML = newHtml;

		d.classList.add("already-duplicated");
	}
}

function bzRetainedInfoSetup(readonly) {
  function lockRelatedCheckboxes(el) {
    // or if we are a graded checkbox, disable other graded checkboxes inside the same bz-box since they are all related
    if(el.getAttribute("type") == "checkbox") {
      var p = el;
      while(p && !p.classList.contains("bz-box"))
        p = p.parentNode;
      if(p) {
        var otherBoxes = p.querySelectorAll("[data-bz-retained][type=checkbox][data-bz-answer]");
        for(var idx = 0; idx < otherBoxes.length; idx++) {
          var item = otherBoxes[idx];
          item.setAttribute("disabled", "disabled");
        }
      }
    }
  }

  function bzChangeRetainedItem(element, value) {
    if(element.tagName == "INPUT" && element.getAttribute("type") == "checkbox"){
      element.checked = (value == "yes") ? true : false;
    } else if(element.tagName == "INPUT" && element.getAttribute("type") == "file"){
    	//
	var n = element.nextSibling;
	if(!n || !n.classList || !n.classList.contains("bz-uploaded-file-display")) {
		n = document.createElement("a");
		n.textContent = "Download File";
		n.className = "bz-uploaded-file-display";
		element.parentNode.insertBefore(n, element.nextSibling);
	}
	n.href = value;
    } else if(element.tagName == "INPUT" && element.getAttribute("type") == "radio"){
      element.checked = (value == element.value) ? true : false;
    } else if(element.tagName == "INPUT" && element.getAttribute("type") == "button"){
      if (value == "clicked"){
       element.className += " bz-was-clicked";
      }
    } else if(element.tagName == "INPUT" || element.tagName == "TEXTAREA"){
      element.value = value;
    } else if(element.tagName == "SELECT") {
      element.value = value;
    } else {
      element.textContent = value;
    }

    if(value != "" && element.hasAttribute("data-bz-answer")) {
      element.setAttribute("disabled", "disabled"); // locked since they set an answer already and mastery cannot be reedited
      lockRelatedCheckboxes(element);
    }
  }

  expandCohortMagicFields();

  if(window.ENV && ENV.current_user) {
    var names = document.querySelectorAll(".bz-user-name");
    for(var i = 0; i < names.length; i++) {
      var element = names[i];
      element.className = "bz-user-name-showing";
      element.textContent = ENV.current_user.display_name;
    }
  }

  var pendingMagicFieldLoads = 0;
  var pendingMagicFieldLoadEvent = false;
  function triggerMagicFieldsLoaded() {
    pendingMagicFieldLoadEvent = false;
    magicFieldsLoaded = true;
    console.log("running on magic fields loaded");
    for(var i = 0; i < onMagicFieldsLoaded.length; i++)
      onMagicFieldsLoaded[i]();
  }

  var magicElementsDOM = document.querySelectorAll("[data-bz-retained]");
  var names = [];
  var magicElements = [];
  for(var i = 0; i < magicElementsDOM.length; i++) {
    (function(el) {
      var name = el.getAttribute("data-bz-retained");

      if(el.className.indexOf("bz-retained-field-setup") != -1)
        return; // already set up, no need to redo

      if(el.tagName == "IMG") {
        // this is a hack so the editor will not allow text inside:
        // the field pretends to be an image in that context. But, when
        // it is time to display it, we want to switch back to being an
        // ordinary span.
        var span = document.createElement("span");
        span.className = el.className;
        span.setAttribute("data-bz-retained", el.getAttribute("data-bz-retained"));
        el.parentNode.replaceChild(span, el);
        el = span;
      }

      var save = function() {
        var value = el.value;
        if(el.getAttribute("type") == "radio"){
          if(!el.checked)
            return; // we only want to actually save the one that is checked
        } else if(el.getAttribute("type") == "checkbox"){
          value = el.checked ? "yes" : "";
        } else if(el.getAttribute("type") == "button"){
          value = "clicked";
          el.className += " bz-was-clicked";
        }
        var optional = false;
        if (el.classList.contains("bz-optional-magic-field"))
          optional = true;

        var actualSaveInternal = function() {
          BZ_SaveMagicField(name, value, optional, el.getAttribute("type"), el.getAttribute("data-bz-answer"), el.getAttribute("data-bz-weight"), el.getAttribute("data-bz-partial-credit"));

          // we also need to update other views on the same page
          var magicElementsDOM = document.querySelectorAll("[data-bz-retained]");
          for(var idx = 0; idx < magicElementsDOM.length; idx++) {
              var item = magicElementsDOM[idx];
              if(item.getAttribute("data-bz-retained") == name)
                bzChangeRetainedItem(item, value);
          }
        };

	var actualSave = function() {
		if(el.type == "file") {
			// upload first, then set the magic field to the URL
			var http = new XMLHttpRequest();
			http.open("POST", "/api/v1/users/self/files");

			var file = el.files[0];

			var data = new FormData();
			data.append("authenticity_token", BZ_AuthToken);
			data.append("utf8", "\u2713");
			data.append("name", file.name);
			data.append("size", file.size);
			data.append("content_type", file.type);

			http.onload = function() {
				var obj = JSON.parse(http.responseText);

				var next = new XMLHttpRequest();
				var data = new FormData();
				next.open("POST", obj.upload_url);
				for(objkey in obj.upload_params) {
					data.append(objkey, obj.upload_params[objkey]);
				}
				data.append("file", file);

				next.onload = function() {
					if(next.status >= 200 && next.status < 300) {
						//var last = new XMLHttpRequest();
						//last.open("GET", next.getResponseHeader("Location"));
						//last.onload = function() {
							var n;
							if(next.responseText.charAt(0) == 'w')
								n = JSON.parse(next.responseText.substring(9)); // last
							else
								n = JSON.parse(next.responseText); // last
							value = n.url;
							actualSaveInternal();
						//};
						//last.send();
					} else if(next.status >= 300 && next.status < 400) {
						var url = next.getResponseHeader("Location");
						var last = new XMLHttpRequest();
						last.open("POST", url);
						last.onload = function() {
							var n = JSON.parse(last.responseText);
							value = n.url;
							actualSaveInternal();
						};
						last.send("");
					}
				};

				next.send(data);
			};

			http.send(data);
		} else {
			actualSaveInternal();
		}
	};

        if(!window.bzQueuedListeners)
          window.bzQueuedListeners = {};

        if(el.hasAttribute("data-bz-answer")) {
          // it is a mastery answer, don't actually save until the next button is pressed (if present)
          var p = el;
          while(p && !p.classList.contains("bz-box"))
            p = p.parentNode;
          if(p) {
            var btn = p.querySelector(".bz-toggle-all-next");
            var wrapper = function() {
              actualSave();
              btn.removeEventListener("click", wrapper);
              window.bzQueuedListeners[name] = null;
            };
            if(btn) {
              if(window.bzQueuedListeners[name])
                btn.removeEventListener("click", window.bzQueuedListeners[name]);
              btn.addEventListener("click", wrapper);
              window.bzQueuedListeners[name] = wrapper;
            } else
              actualSave();
          } else {
            actualSave();
          }
        } else {
          actualSave();
        }
      };

      el.className += " bz-retained-field-setup";

      if(readonly !== true) {
        if (el.getAttribute("type") == "button")
          el.addEventListener("click", save);
        else
          el.addEventListener("change", save);
      } else {
        el.className += " bz-retained-field-readonly";
      }

      pendingMagicFieldLoads += 1;
      names.push(name);
      magicElements.push(el);

      if(el.classList.contains("bz-industries")) {
        BZ_Industries_List.forEach(function(ind) {
          var option = document.createElement("option");
          option.value = ind;
          option.textContent = ind;
          el.appendChild(option);
        });
      }
    })(magicElementsDOM[i]);
  }

  BZ_LoadMagicFields(names, function(obj) {
    for(var i = 0; i < names.length; i++) {
      var name = names[i];
      var el = magicElements[i];

      var value = obj[name];

      bzChangeRetainedItem(el, value);
      pendingMagicFieldLoads -= 1;
      if(pendingMagicFieldLoads == 0 && !pendingMagicFieldLoadEvent) {
        pendingMagicFieldLoadEvent = true;
        window.requestAnimationFrame(triggerMagicFieldsLoaded);
        console.log("THE MAGIC HAPPENS");
      }
    }
  });
  // old one, w don't need all that info though so cutting it off while batching to optimize network use
  // http.open("GET", "/bz/user_retained_data?name=" + encodeURIComponent(name) + "&value=" + encodeURIComponent(el.value) + "&type=" + el.getAttribute("type"), true);
}

if(window != window.top) {
  // we are in an iframe... strip off magic
  document.getElementsByTagName("html")[0].className += " bz-in-iframe";
}


function getInnerHtmlWithMagicFieldsReplaced(ele) {

  expandCohortMagicFields(ele);

  // we need to copy the textarea values into the html
  // text because otherwise cloneNode will discard it, and
  // the info won't be copied to the submission
  var ta = ele.querySelectorAll("textarea");
  for(var i = 0; i < ta.length; i++)
  	ta[i].textContent = ta[i].value;

  var html = ele.cloneNode(true);
  var magicFields = html.querySelectorAll("[data-bz-retained]");
  for(var i = 0; i < magicFields.length; i++) {
    var o = magicFields[i];
    var n;
    if(o.tagName == "TEXTAREA") {
      n = document.createElement("div");
      var h = o.value.
        replace("&", "&amp;").
        replace("\"", "&quot;").
        replace("<", "&lt;").
        replace("\n", "<br />");
      n.innerHTML = h;
    } else if(o.tagName == "INPUT" && o.getAttribute("type") == "checkbox") {
      n = document.createElement("span");
      n.textContent = o.checked ? "[X]" : "[ ]";
    } else if(o.tagName == "INPUT" && o.getAttribute("type") == "radio") {
      n = document.createElement("span");
      n.textContent = o.checked ? "[O]" : "[ ]";
    } else {
      n = document.createElement("span");
      n.textContent = o.value;
    }
    n.className = "bz-retained-field-replaced";
    o.parentNode.replaceChild(n, o);
  }

  return "<div class=\"bz-magic-field-submission\">" + html.innerHTML + "</div>";
}

function copyAssignmentDescriptionIntoAssignmentSubmission() {
  var desc = document.querySelector("#assignment_show .description");

  var html = getInnerHtmlWithMagicFieldsReplaced(desc);

  var bodHtml = tinyMCE.get("submission_body");
  if(bodHtml)
    bodHtml.setContent(html);

  var bod = document.getElementById("submission_body");
  bod.value = html;
}

// this is called in the canvas file public/javascripts/submit_assignment.js
// to be a custom validator
function validateMagicFields() {
  var list = document.querySelectorAll("#assignment_show .description input[type=text][data-bz-retained], #assignment_show .description input[type=url][data-bz-retained], #assignment_show .description textarea[data-bz-retained]");
  for(var a = 0; a < list.length; a++) {
    if(list[a].value == "" && !list[a].classList.contains("bz-optional-magic-field")) {
      alert('You have incomplete fields in this project. Go back and complete them before submitting.');
      list[a].focus();
      return false;
    }
  }

  return true;
}

function prepareAssignmentSubmitWithMagicFields() {
  // only do this if we put magic field editors in the assignment
  if(!document.querySelector("#assignment_show .description input[data-bz-retained], #assignment_show .description textarea[data-bz-retained]"))
    return;

  var as = document.querySelector("#assignment_show .description");
  as.className += " bz-magic-field-assignment";

  var holder = document.getElementById("submit_assignment");
  holder.className += " bz-magic-field-submit";

  // going to hide the UI
  var tab = document.querySelector("#submit_assignment_tabs li > a.submit_online_text_entry_option");
  if(tab)
    tab.parentNode.style.display = "none";

  var tabcontent = document.querySelector("#submit_assignment_online_text_form_holder");
  if(tabcontent) {
    tabcontent.style.display = "none";

    copyAssignmentDescriptionIntoAssignmentSubmission(); // copy it initially
  }

  // and copy it again on submit in case it changed in the mean time...
  var form = document.getElementById("submit_online_text_entry_form");
  if(form)
  form.addEventListener("submit", function(event) {
    copyAssignmentDescriptionIntoAssignmentSubmission();
  }, true);
}

/* We need instant survey here to ensure it is loaded before the
   canvas JS to avoid undefined function problems */
function bzActivateInstantSurvey(magic_field_name) {
        var i = document.getElementById("instant-survey");
	if(!i) return;

	// adjust styles of the container to make room  (see CSS)
	var msf = document.querySelector(".module-sequence-footer");
	var originalMsfButtonClass = msf.className;
	msf.className += ' has-instant-survey';

	// discourage clicking of next without answering first...
	var nb = document.querySelector(".bz-next-button");
	var originalNextButtonClass = nb.className;
	nb.className += ' discouraged';

	// move the survey from the hidden body to the visible footer
        var h = document.getElementById("instant-survey-holder");
        h.innerHTML = "";
        h.appendChild(i.parentNode.removeChild(i));

	var count = h.querySelectorAll("input").length;
	if(count < 3)
		msf.className += ' has-short-instant-survey';
	else if(count == 3)
		msf.className += ' has-3-instant-survey';
	else if(count == 4)
		msf.className += ' has-4-instant-survey';

	// react to survey click - save and encourage hitting the next button.

	var save = function(value, optional) {
		var http = new XMLHttpRequest();
		http.open("POST", "/bz/user_retained_data", true);
		var data = "name=" + encodeURIComponent(magic_field_name) + "&value=" + encodeURIComponent(value) + "&from=" + encodeURIComponent(location.href);
                if(!optional)
                  data += "&optional=1";
		http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

		// encourage next clicking again once they are saved
		http.onload = function() {
			nb.className = originalNextButtonClass;
          		var h = document.getElementById("instant-survey-holder");
			$(h).hide("slow");
			// shrinks the container...
			msf.className = originalMsfButtonClass;
		};

		http.send(data);
	};

	var inputs = i.querySelectorAll("input");
	for(var a = 0; a < inputs.length; a++) {
		inputs[a].onchange = function() {
			save(this.value, this.classList.contains("bz-optional-magic-field"));
		};
	}
}

function bzInitializeInstantSurvey() {
	// only valid on wiki pages
	if(ENV == null || ENV["WIKI_PAGE"] == null || ENV["WIKI_PAGE"].page_id == null)
		return;

	// if there's no survey in the document, don't need to query.
        var i = document.getElementById("instant-survey");
        if(!i)
	  return;

	// show the button for editors (if present) if a survey exists
	var ssrbtn = document.getElementById("see-survey-results-button");
	if(ssrbtn)
	  ssrbtn.style.display = '';


	// our key in the user magic field data where responses are stored
	var name = "instant-survey-" + ENV["WIKI_PAGE"].page_id;

	// load the value first. If it is already set, no need to show -
	// instant survey is supposed to only be done once.

	var http = new XMLHttpRequest();
	// cut off json p stuff
	http.onload = function() {
		var value = http.responseText.substring(9);
		if(value == null || value == "")
			bzActivateInstantSurvey(name);
	};
	http.open("GET", "/bz/user_retained_data?name=" + encodeURIComponent(name), true);
	http.send();

}

function BZ_ModalDialog(titleString, bodyElement, onOK) {
  var holder = document.createElement("div");
  holder.setAttribute("id", "bz-fullscreen_modal");
  var inner = document.createElement("div");
  holder.appendChild(inner);

  var title = document.createElement("h1");
  title.textContent = titleString;
  inner.appendChild(title);

  var bodyHolder = document.createElement("div");
  bodyHolder.className = "bz-fullscreen_modal-body_holder";
  inner.appendChild(bodyHolder);

  var buttonsHolder = document.createElement("div");
  buttonsHolder.className = "bz-fullscreen_modal-buttons_holder";
  inner.appendChild(buttonsHolder);

  var cancelButton = document.createElement("button");
  cancelButton.setAttribute("type", "button");
  cancelButton.className = "bz-fullscreen_modal-cancel_button";
  cancelButton.textContent = "Cancel";
  cancelButton.onclick = function() {
    document.body.removeChild(holder);
  };
  buttonsHolder.appendChild(cancelButton);

  var okButton = document.createElement("button");
  okButton.setAttribute("type", "button");
  okButton.className = "bz-fullscreen_modal-ok_button";
  okButton.textContent = "OK";
  okButton.onclick = function() {
    onOK();
    document.body.removeChild(holder);
  };
  buttonsHolder.appendChild(okButton);

  document.body.appendChild(holder);

  bodyHolder.appendChild(bodyElement);
}

var BZ_MasterBankCourseId = 1;

function BZ_SetupMasterPageClone(page_id) {
    var req = new XMLHttpRequest();
    req.open("GET", "/api/v1/courses/"+BZ_MasterBankCourseId+"/pages", true);
    req.onload = function(e) {
      if(req.status == 200) {
        var obj = JSON.parse(req.responseText.substring(9));
        var select = document.createElement("select");
        for(var i = 0; i < obj.length; i++) {
          var option = document.createElement("option");
          option.setAttribute("value", obj[i].page_id);
          option.textContent = obj[i].title;
          select.appendChild(option);
        }

        var div = document.createElement("div");
        var p = document.createElement("p");
        p.textContent = "Warning: This will erase all existing content and replace it with the bank content!";
        div.appendChild(p);
        div.appendChild(select);

        BZ_ModalDialog("Choose a page to clone", div, function() {
          var pid = select.options[select.selectedIndex].value;
          BZ_SetCloneMasterPage(page_id, pid);
        });

      } else {
        console.log(req.status);
        alert("Failure to load: " + req.status);
      }
    };
    req.send('');

}

function BZ_DetachFromMasterPage(page_id) {
  BZ_SetCloneMasterPage(page_id, '');
}

function BZ_SetCloneMasterPage(page_id, new_master) {
    var req = new XMLHttpRequest();
    var data = new FormData();
    data.append("utf8", "\u2713");
    data.append("authenticity_token", BZ_AuthToken);
    data.append("wiki_page[clone_of_id]", new_master);
    req.open("PUT", "/api/v1/courses/"+BZ_MasterBankCourseId+"/pages/" + page_id, true);
    req.onload = function(e) {
      if(req.status == 200) {
        var obj = JSON.parse(req.responseText);

        location.reload();
      } else {
        console.log(req.status);
        alert("Failure to save: " + req.status + " on " + page_id);
      }
    };
    req.send(data);

}

function BZ_GoToMasterPage(master_page_id) {
    var req = new XMLHttpRequest();
    req.open("GET", "/api/v1/courses/"+BZ_MasterBankCourseId+"/pages/" + master_page_id, true);
    req.onload = function(e) {
      if(req.status == 200) {
        var obj = JSON.parse(req.responseText.substring(9));

        location.href = "/courses/" + BZ_MasterBankCourseId + "/pages/" + obj.url;
      } else {
        console.log(req.status);
        alert("Failure to load: " + req.status);
      }
    };
    req.send('');
}

var BZ_MagicFieldSaveTimeouts = {};

function BZ_SaveMagicField(field_name, field_value, optional, type, answer, weight, partialCredit) {
  if(optional == null)
    optional = true; // the default is to skip grading; assume api updates are optional fields
  if(type == null)
    type = "api";
  if(weight == null)
    weight = 1;

  // if there's an existing retry, cancel it so it doesn't
  // race condition overwrite a subsequent write; we only
  // want to retry the most recent content
  if(BZ_MagicFieldSaveTimeouts[field_name])
    clearTimeout(BZ_MagicFieldSaveTimeouts[field_name]);

  var http = new XMLHttpRequest();
  http.open("POST", "/bz/user_retained_data", true);
  var data = "name=" + encodeURIComponent(field_name) + "&value=" + encodeURIComponent(field_value) + "&type=" + type;
  if (optional)
    data += "&optional=true";
  if (answer !== null)
    data += "&answer=" + encodeURIComponent(answer);
  if (weight !== null)
    data += "&weight=" + encodeURIComponent(weight);
  if (partialCredit !== null)
    data += "&partial_credit=" + encodeURIComponent(partialCredit);

  http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  http.onreadystatechange = function() {
    if(http.readyState == 4) {
      if(http.status != 200) {
        if(http.status == 0) {
          // network error
          var offlineWarning = document.getElementById("bz-offline-warning");
          if(offlineWarning)
            offlineWarning.style.display = "";
          // automatically retry in a little while
          var timeout = setTimeout(function() {
            BZ_MagicFieldSaveTimeouts[field_name] = null;
            BZ_SaveMagicField(field_name, field_value, optional, type, answer);
          }, 5000);
          BZ_MagicFieldSaveTimeouts[field_name] = timeout;
        } else {
          // returned error from Canvas...
          // should be a code error on our side
          // so just gonna log
          console.log("Magic error: " + http.status + " " + field_name + "=" + field_value);
        }
      } else {
        // success, we can hide the warning again if it is showing
        var offlineWarning = document.getElementById("bz-offline-warning");
        if(offlineWarning)
          offlineWarning.style.display = "none";

        var responseJson = http.responseText;
        console.log(responseJson);
        var res = JSON.parse(responseJson);
        if(res["points_reason"] == "past_due") {
          var lateWarning = document.getElementById("bz-late-warning");
          if(lateWarning)
            lateWarning.style.display = "";
        }
      }
    }
  };
  http.send(data);
}

// field_names is an array!
// callback is a function(obj) { } the properties on obj are name and value
// so like BZ_LoadMagicFields(["foo", "bar"], function(obj) { obj["foo"] == "value_of_foo"; obj["bar"] = "value_of_var"; });
function BZ_LoadMagicFields(field_names, callback) {

  var http = new XMLHttpRequest();
  http.onload = function() {
    // substring is to cut off json p stuff if we go back to GET, unneeded with POST though
    var json = http.responseText; //.substring(9)
    var obj = JSON.parse(json);

    callback(obj);
  };

  var data = "";
  for(var i = 0; i < field_names.length; i++) {
    if(data.length)
      data += "&";
    data += "names[]=" + encodeURIComponent(field_names[i]);
  }

  // I would LIKE to use get on this, but since the name list can be arbitrarily long
  // and I don't want to risk hitting a browser/server limit of url length, I am going to
  // POST just in case
  http.open("POST", "/bz/user_retained_data_batch", true);
  http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  http.send(data);
}


function bzWikiPageContentPreload(wikipage, finalize_page_show) {
    var parser = new DOMParser();
    var doc = parser.parseFromString("<div class=\"bz-modified\">" + wikipage["body"] + "</div>", "text/html");

    function finalize_page_show_wrapped() {
        var serializer = new XMLSerializer();
        wikipage["body"] = serializer.serializeToString(doc);

        finalize_page_show(wikipage);
    }

    var replacements = doc.querySelectorAll("div[data-replace-with-page]");
    if(replacements.length) {
        var pagesToLoad = [];
        var pagesToLoadHash = {};
        for(var i = 0; i < replacements.length; i++) {
            var pn = replacements[i].getAttribute("data-replace-with-page");
            if(!pagesToLoadHash[pn]) {
                pagesToLoadHash[pn] = true;
                pagesToLoad.push(pn);
            }
        }

        var http = new XMLHttpRequest();
        http.onload = function() {
            // substring is to cut off json p stuff
            var json = http.responseText.substring(9)
            var obj = JSON.parse(json);

            for(var i = 0; i < replacements.length; i++) {
                var pn = replacements[i].getAttribute("data-replace-with-page");
                if(obj[pn]) {
                    replacements[i].innerHTML = obj[pn];
                    replacements[i].setAttribute("data-replaced-with-page", pn);
                    replacements[i].removeAttribute("data-replace-with-page");
                }
            }

            finalize_page_show_wrapped();
       };

        var data = "";
        for(var i = 0; i < pagesToLoad.length; i++) {
           data += "&";
           data += "names[]=" + encodeURIComponent(pagesToLoad[i]);
        }

        http.open("GET", "/bz/load_wiki_pages?course_id=" + ENV["COURSE_ID"] + data, true);
        http.send(data);
    } else {
        finalize_page_show_wrapped();
    }
}

var BZ_Industries_List = [
      '',
      'Accounting',
      'Advertising',
      'Aerospace',
      'Banking',
      'Beauty / Cosmetics',
      'Biotechnology ',
      'Business',
      'Chemical',
      'Communications',
      'Computer Engineering',
      'Computer Hardware ',
      'Education',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage ',
      'Health',
      'Information Technology',
      'Insurance',
      'Journalism / News / Media',
      'Law',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Medical Devices & Supplies',
      'Performing Arts ',
      'Pharmaceutical ',
      'Public Administration',
      'Public Relations',
      'Publishing',
      'Marketing ',
      'Real Estate ',
      'Sports ',
      'Technology ',
      'Telecommunications',
      'Tourism',
      'Transportation / Travel',
      'Writing'
    ];
