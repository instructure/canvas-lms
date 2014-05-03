/* global ScriptEngineMajorVersion: false, escape: false */
define(['jquery'], function($) {
  var classesToAdd, userAgent, isIEGreaterThan10;
  var addClasses = true;
  var classifyIE = function(version) {
    version = parseInt(version, 10);
    INST.browser['ie' + version] = INST.browser.ie = true;
    INST.browser.version = version;
  };

  // for backwards compat, this might be defined already but we expose
  // it as a module here
  if (typeof INST === 'undefined') INST = {};

  // ============================================================================================
  // = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
  // = and add a css class to the body for that browser                                       =
  // ============================================================================================
  INST.browser = {};

  // IE detection:
  // Versions 7, 8, and 9 are detected using conditional comments:
  $.each([7,8,9], function(i, versionNumber) {
    if ($('html').hasClass('ie'+versionNumber)) {
      classifyIE(versionNumber);
    }
  });

  // Conditional comments were dropped as of IE10, so we need to sniff.
  //
  // See: http://msdn.microsoft.com/en-us/library/ie/hh801214(v=vs.85).aspx
  if (!INST.browser.ie) {
    userAgent = navigator.userAgent;
    isIEGreaterThan10 = /\([^\)]*Trident[^\)]*rv:([\d\.]+)/.exec(userAgent);
    if (isIEGreaterThan10) {
      if ('ScriptEngineMajorVersion' in window &&
        typeof ScriptEngineMajorVersion === 'function') {
        classifyIE(ScriptEngineMajorVersion());
      } else {
        classifyIE(isIEGreaterThan10[1]);
      }

      // don't add the special "ie" class for IE10+ because their renderer is
      // not far behind Gecko and Webkit
      addClasses = false;
    }
    // need to eval here because the optimizer will strip any comments, so using
    // /*@cc_on@*/ will not make it through:
    else if (eval('/*@cc_on!@*/0')) {
      classifyIE(10);
      addClasses = false;
    }
  }

  // Test for WebKit.
  //
  // The IE test is needed because IE11+ defines this property too.
  if (window.devicePixelRatio && !INST.browser.ie) {
    INST.browser.webkit = true;

    //from: http://www.byond.com/members/?command=view_post&post=53727
    INST.browser[(escape(navigator.javaEnabled.toString()) == 'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D') ? 'chrome' : 'safari'] = true;
  }

  //this is just using jquery's browser sniffing result of if its firefox, it
  //should probably use feature detection
  INST.browser.ff = $.browser.mozilla;

  INST.browser.touch       = 'ontouchstart' in document;
  INST.browser['no-touch'] = !INST.browser.touch;

  // now we have some degree of knowing which of the common browsers it is,
  // on dom ready, give the body those classes
  // so for example, if you were on IE6 the body would have the classes "ie" AND "ie6"
  if (addClasses) {
    classesToAdd = $.map(INST.browser, function(v,k){ if (v === true) return k }).join(' ');
    $(function(){
      $('body').addClass(classesToAdd);
    });
  }

  return INST;
});

