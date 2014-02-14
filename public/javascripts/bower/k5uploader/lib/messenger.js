define([], function(){

  Messenger.decorate = function(instance) {
    instance.messenger = new Messenger();
    instance.addEventListener = function(eventName, method) {
      instance.messenger.addEventListener(eventName, method);
    }
    instance.dispatchEvent = function(eventName, data, context) {
      instance.messenger.dispatchEvent(eventName, data, context);
    }
    instance.removeEventListener = function(eventName, targetMethod) {
      instance.messenger.removeEventListener(eventName, targetMethod);
    }
  }

  function Messenger (){
    this.events = {};
  }

  Messenger.prototype.killAllListeners = function(eventName) {
    if(this.events[eventName]) {
      this.events[eventName] = []
    } else {
      return false
    }
  };

  Messenger.prototype.destroy = function() {
    this.events = {};
  };

  Messenger.prototype.dispatchEvent = function(eventName, data, context) {
    if(this.events[eventName]) {
      this.events[eventName].forEach(function(eventHandler){
        eventHandler.call(context, data);
      });
    }
  };

  Messenger.prototype.addEventListener = function(eventName, method) {
    if (!method) {
      return false
    }
    if (!this.events[eventName]) {
      this.events[eventName] = [];
    }
    this.events[eventName].push(method);
    return method
  };

  Messenger.prototype.removeEventListener = function(eventName, targetMethod) {
    if(this.events[eventName]) {
      var eventHandlers = this.events[eventName];
      var removalQueue = []
      this.events[eventName].forEach(function(eventHandler, index){
        if(eventHandler === targetMethod) {
          removalQueue.push(index);
        }
      });
      if(removalQueue.length > 0) {
        removalQueue.forEach(function(element) {
          eventHandlers.splice(element, 1);
        });
      }
    }
  };

  return Messenger

});
