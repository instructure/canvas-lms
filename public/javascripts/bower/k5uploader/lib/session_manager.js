define([
  './message_bus',
  './k5_options',
  './kaltura_session',
], function(
  messageBus,
  k5Options,
  KalturaSession
){
  function SessionManager (){
    this.sessionData = new KalturaSession();
  }

  SessionManager.prototype.loadSession = function() {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", k5Options.sessionUrl, true);
    xhr.responseType = 'json';
    xhr.onload = this.onSessionLoaded.bind(this);
    xhr.send();
  };

  SessionManager.prototype.onSessionLoaded = function(e) {
    var xhr = e.target;
    if (xhr.status == 200) {
      this.sessionData.setSession(xhr.response);
      messageBus.dispatchEvent('SessionManager.complete', this.sessionData, this);
    } else {
      messageBus.dispatchEvent('SessionManager.error');
    }
  };

  SessionManager.prototype.getSession = function() {
    return this.sessionData;
  };

  return SessionManager

}
);
