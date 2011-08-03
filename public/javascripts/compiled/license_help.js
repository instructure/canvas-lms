(function() {
  I18n.scoped("license_help", function(I18n) {
    var checkButton, licenceTypes, toggleButton, uncheckButton;
    licenceTypes = ["by", "nc", "nd", "sa"];
    toggleButton = function(el, check) {
      return $(el).toggleClass('selected', !!check).attr('aria-checked', !!check);
    };
    checkButton = function(el) {
      return toggleButton(el, true);
    };
    uncheckButton = function(el) {
      return toggleButton(el, false);
    };
    return $(".license_help_link").live("click", function(event) {
      var $dialog, $select;
      event.preventDefault();
      $dialog = $("#license_help_dialog");
      $select = $(this).prev("select");
      if ($dialog.length === 0) {
        $dialog = $("<div/>").attr("id", "license_help_dialog").hide().loadingImage().appendTo("body").delegate(".option", "click", function(event) {
          var select;
          event.preventDefault();
          select = !$(this).is('.selected');
          toggleButton(this, select);
          if (select) {
            checkButton($dialog.find(".option.by"));
            if ($(this).hasClass("sa")) {
              uncheckButton($dialog.find(".option.nd"));
            } else if ($(this).hasClass("nd")) {
              uncheckButton($dialog.find(".option.sa"));
            }
          } else if ($(this).hasClass("by")) {
            uncheckButton($dialog.find(".option"));
          }
          $dialog.triggerHandler("option_change");
        }).delegate(".select_license", "click", function() {
          if ($dialog.data("select")) {
            $dialog.data("select").val($dialog.data("current_license") || "private");
          }
          return $dialog.dialog("close");
        }).bind("license_change", function(event, license) {
          var type, _i, _len, _results;
          $dialog.find(".license").removeClass("active").filter("." + license).addClass("active");
          uncheckButton($dialog.find(".option"));
          if ($dialog.find(".license.active").length === 0) {
            license = "private";
            $dialog.find(".license.private").addClass("active");
          }
          $dialog.data("current_license", license);
          if (license.match(/^cc/)) {
            _results = [];
            for (_i = 0, _len = licenceTypes.length; _i < _len; _i++) {
              type = licenceTypes[_i];
              if (type === 'by' || license.match("_" + type)) {
                _results.push(checkButton($dialog.find(".option." + type)));
              }
            }
            return _results;
          }
        }).bind("option_change", function() {
          var args, license, type, _i, _len;
          args = ["cc"];
          for (_i = 0, _len = licenceTypes.length; _i < _len; _i++) {
            type = licenceTypes[_i];
            if ($dialog.find(".option." + type).is(".selected")) {
              args.push(type);
            }
          }
          license = (args.length === 1 ? "private" : args.join("_"));
          return $dialog.triggerHandler("license_change", license);
        }).dialog({
          autoOpen: false,
          title: I18n.t("content_license_help", "Content Licensing Help"),
          width: 700
        });
        $.get("/partials/_license_help.html", function(html) {
          return $dialog.loadingImage('remove').html(html).triggerHandler("license_change", $select.val() || "private");
        });
      }
      $dialog.find(".select_license").showIf($select.length);
      $dialog.data("select", $select);
      $dialog.triggerHandler("license_change", $select.val() || "private");
      return $dialog.dialog("open");
    });
  });
}).call(this);
