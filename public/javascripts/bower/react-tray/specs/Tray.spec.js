require('./helper');

describe('react-tray', function () {
  afterEach(function () {
    unmountTray();
  });

  it('should not be visible when isOpen is false', function () {
    renderTray();
    equal(document.querySelectorAll('.ReactTray__Content').length, 0);
  });

  it('should be visible when isOpen is true', function () {
    renderTray({isOpen: true});
    equal(document.querySelectorAll('.ReactTray__Content').length, 1);
  });

  it('should receive focus when opened', function () {
    renderTray({isOpen: true});
    equal(document.querySelector('.ReactTray__Content'), document.activeElement);
  });

  it('should call onBlur when closed', function () {
    var blurred = false;
    renderTray({isOpen: true, onBlur: function () { blurred: true; }, closeTimeoutMS: 0});
    TestUtils.Simulate.click(document.querySelector('.ReactTray__Overlay'));
    setTimeout(function () {
      equal(blurred, true);
    }, 0);
  });

  it('should close on overlay click', function () {
    renderTray({isOpen: true, onBlur: function () {}, closeTimeoutMS: 0});
    TestUtils.Simulate.click(document.querySelector('.ReactTray__Overlay'));
    setTimeout(function () {
      equal(document.querySelectorAll('.ReactTray__Content').length, 0);
    }, 0);
  });

  it('should close on ESC key', function () {
    renderTray({isOpen: true, onBlur: function () {}, closeTimeoutMS: 0});
    TestUtils.Simulate.keyDown(document.querySelector('.ReactTray__Content'), {key: 'Esc'});
    setTimeout(function () {
      equal(document.querySelectorAll('.ReactTray__Content').length, 0);
    }, 0);
  });
});
