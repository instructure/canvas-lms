import $ from 'jquery'
import ToolLaunchResizer from './tool_launch_resizer'

var beforeUnloadHandler;
function setUnloadMessage(msg) {
  removeUnloadMessage();

  beforeUnloadHandler = function(e) {
    return (e.returnValue = msg || "");
  }
  window.addEventListener('beforeunload', beforeUnloadHandler);
}

function removeUnloadMessage() {
  if (beforeUnloadHandler) {
    window.removeEventListener('beforeunload', beforeUnloadHandler);
    beforeUnloadHandler = null;
  }
}

function findDomForWindow(sourceWindow) {
  const iframes = document.getElementsByTagName("IFRAME");
  for (let i=0; i < iframes.length; i += 1) {
    if (iframes[i].contentWindow === sourceWindow) {
      return iframes[i];
    }
  }
  return null;
}

export function ltiMessageHandler(e) {
  try {
    var message = JSON.parse(e.data);
    switch (message.subject) {
      case 'lti.frameResize':
      const toolResizer = new ToolLaunchResizer();
      var height = message.height;
      if (height <= 0) height = 1;

      const container = toolResizer.tool_content_wrapper(message.token || e.origin).data('height_overridden', true);
      // If content.length is 0 then jquery didn't the tool wrapper.
      if (container.length > 0) {
        toolResizer.resize_tool_content_wrapper(height, container);
      } else {
        // Attempt to find an embedded iframe that matches the event source.
        const iframe = findDomForWindow(e.source);
        if (iframe) {
          if (typeof height === 'number') {
            height = height + 'px';
          }
          iframe.height = height;
          iframe.style.height = height;
        }
      }
      break;

      case 'lti.showModuleNavigation':
        if(message.show === true || message.show === false){
          $('.module-sequence-footer').toggle(message.show);
        }
        break;

      case 'lti.scrollToTop':
        $('html,body').animate({
           scrollTop: $('.tool_content_wrapper').offset().top
         }, 'fast');
        break;

      case 'lti.setUnloadMessage':
        setUnloadMessage(htmlEscape(message.message));
        break;

      case 'lti.removeUnloadMessage':
        removeUnloadMessage();
        break;

      case 'lti.screenReaderAlert':
        $.screenReaderFlashMessageExclusive(message.body.html || message.body)
        break;
    }
  } catch(err) {
    (console.error || console.log).call(console, 'invalid message received from');
  }
}

export function monitorLtiMessages() {
  window.addEventListener('message', function(e) {
    ltiMessageHandler(e);
  });
}
