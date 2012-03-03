define(['jquery'], function($) {
  // for backwards compat, this might be defined already but we expose
  // it as a module here
  if (typeof INST === 'undefined') INST = {};

  // ============================================================================================
  // = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
  // = and add a css class to the body for that browser                                       =
  // ============================================================================================
  INST.browser = {};
  $.each([7,8,9], function(i, versionNumber) {
    if ($('html').hasClass('ie'+versionNumber)) {
      INST.browser['ie'+versionNumber] = INST.browser.ie = true;
      INST.browser.version = versionNumber;
    }
  });

  if (window.devicePixelRatio) {
    INST.browser.webkit = true;

    //from: http://www.byond.com/members/?command=view_post&post=53727
    INST.browser[(escape(navigator.javaEnabled.toString()) == 'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D') ? 'chrome' : 'safari'] = true;
  }

  //this is just using jquery's browser sniffing result of if its firefox, it should probably use feature detection
  INST.browser.ff = $.browser.mozilla;

  // now we have some degree of knowing which of the common browsers it is, on dom ready, give the body those classes
  // so for example, if you were on IE6 the body would have the classes "ie" AND "ie6"
  var classesToAdd = $.map(INST.browser, function(v,k){ if (v === true) return k }).join(' ');
  $(function(){
    $('body').addClass(classesToAdd);
  });

  return INST;
});

