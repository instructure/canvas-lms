define([], function(){
  var authenticationProviders = {
    hideAllNewAuthTypeForms: function(){
      var newForms = document.querySelectorAll(".auth-form-container--new");
      Array.prototype.forEach.call(newForms, function(el, id){
        el.style.display = "none";
      });
    },

    showFormFor: function(authType){
      var formId = authType + "_form";
      var form =  document.getElementById(formId);
      if(form !== null){
        form.style.display = "";
        setTimeout(function(){
          $(form).find(":text:first").focus();
          form.scrollIntoView();
        }, 100);
      }
    },

    hideNoAuthMessage: function(){
      var noAuthMessage = document.getElementById("no_auth");
      if(noAuthMessage !== null){
        noAuthMessage.style.display = "none";
      }
    },

    changedAuthType: function(authType){
      authenticationProviders.hideNoAuthMessage();
      authenticationProviders.hideAllNewAuthTypeForms();
      authenticationProviders.showFormFor(authType);
    }
  };

  return authenticationProviders;
});
