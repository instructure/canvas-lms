  var resume = document.getElementById("resume");

  var activePoint = null;

  var saveButton = document.querySelector("#commentary button");
  saveButton.addEventListener("click", function(event) {
      var xhr = new XMLHttpRequest();
      var url = "/bz/submission_comment";
      xhr.open("POST", url, true);
      xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      var ta = document.querySelector("#commentary textarea");
      var args = "comment=" + encodeURIComponent(ta.value);
      args += "&x=" + activePoint.getAttribute("data-x");
      args += "&y=" + activePoint.getAttribute("data-y");
      args += "&authenticity_token=" + encodeURIComponent(authtoken);
      args += "&submission_id=" + encodeURIComponent(submission_id);
      args += "&attachment_id=" + encodeURIComponent(attachment_id);
      xhr.send(args);
      var commentary = document.getElementById("commentary");
      commentary.style.display = "";

      activePoint.setAttribute("title", ta.value);
      ta.value = "";
  });

  function showCommentaryOn(e) {
      var o = document.querySelector(".point.current");
      if(o)
        o.classList.remove("current");
      e.classList.add("current");

      var commentary = document.getElementById("commentary");
      commentary.style.left = (e.offsetLeft+0) + "px";
      commentary.style.top = (e.offsetTop+20) + "px";
      commentary.style.display = "block";

      if(readonly)
        commentary.classList.add("readonly");

      activePoint = e;

      var ta = commentary.querySelector("textarea");
      ta.value = e.getAttribute("title");
      if(readonly)
        ta.setAttribute("readonly", "readonly");
      ta.focus();
  }


  // mousedown?
  resume.addEventListener("click", function(event) {

    if(event.target.tagName == "IMG") {
      var o = document.querySelector(".point.current");
      if(o)
        o.classList.remove("current");

      var commentary = document.getElementById("commentary");

      if(readonly) {
        commentary.style.display = "none";
        return;
      }

      var point = document.createElement("div");
      point.className = "point current";
      point.style.left = (event.offsetX-8) + "px";
      point.style.top = (event.offsetY-8) + "px";
      point.textContent = ++count;

      point.setAttribute("data-x", event.offsetX);// * 1000 / event.target.offsetWidth);
      point.setAttribute("data-y", event.offsetY);// * 1000 / event.target.offsetHeight);

      resume.appendChild(point);

      activePoint = point;

      commentary.style.left = (event.offsetX-8) + "px";
      commentary.style.top = (event.offsetY+12) + "px";
      commentary.style.display = "block";

      var ta = commentary.querySelector("textarea");
      ta.focus();
    } else if(event.target.classList.contains("point")) {
      showCommentaryOn(event.target);
    }
  });

  (function() {
    var highlight = document.querySelector(".highlighted.point");
    if(!highlight) return;
    showCommentaryOn(highlight);
  })();
