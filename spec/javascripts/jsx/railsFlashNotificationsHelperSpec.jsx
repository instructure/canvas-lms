define([
  'i18n!shared.flash_notices',
  'jquery',
  'underscore',
  'str/htmlEscape',
  'jsx/railsFlashNotificationsHelper'
], (I18n, $, _, htmlEscape, NotificationsHelper) => {
  let helper;
  let fixtures;

  module('RailsFlashNotificationsHelper#holderReady', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      helper = new NotificationsHelper();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('returns false if holder is initilialized without the flash message holder in the DOM', () => {
    fixtures.innerHTML = '';

    helper.initHolder();

    ok(!helper.holderReady());
  });

  test('returns false before the holder is initialized even with flash message holder in the DOM', () => {
    fixtures.innerHTML = '<div id="flash_message_holder"></div>';

    ok(!helper.holderReady());
  });

  test('returns true after the holder is initialized with flash message holder in the DOM', () => {
    fixtures.innerHTML = '<div id="flash_message_holder"></div>';

    helper.initHolder();

    ok(helper.holderReady());
  });

  module('RailsFlashNotificationsHelper#getIconType', {
    setup: function() {
      helper = new NotificationsHelper();
    }
  });

  test('returns check when given success', () => {
    equal(helper.getIconType('success'), 'check');
  });

  test('returns warning when given warning', () => {
    equal(helper.getIconType('warning'), 'warning');
  });

  test('returns warning when given error', () => {
    equal(helper.getIconType('error'), 'warning');
  });

  test('returns info when given any other input', () => {
    equal(helper.getIconType('some input'), 'info');
  });

  module('RailsFlashNotificationsHelper#generateNodeHTML', {
    setup: function() {
      helper = new NotificationsHelper();
    }
  });

  test('properly injects type, icon, and content into html', () => {
    let result = helper.generateNodeHTML('success', 'Some Data');

    ok(result.search('class="ic-flash-success"') !== -1);
    ok(result.search('class="icon-check"') !== -1);
    ok(result.search('Some Data') !== -1);
  });

  module('RailsFlashNotificationsHelper#createNode', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      fixtures.innerHTML = '<div id="flash_message_holder"></div>';

      helper = new NotificationsHelper();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  })

  test('does not create a node before the holder is initialized', () => {
    helper.createNode('success', 'Some Data');

    let holder = document.getElementById('flash_message_holder');

    equal(holder.firstChild, null);
  });

  test('creates a node', () => {
    helper.initHolder();
    helper.createNode('success', 'Some Other Data');

    let holder = document.getElementById('flash_message_holder');

    equal(holder.firstChild.tagName, 'LI');
  });

  test('properly adds css options when creating a node', ()  => {
    helper.initHolder();

    let css = {'width': '300px', 'direction': 'rtl'};

    helper.createNode('success', 'Some Third Data', 3000, css);

    let holder = document.getElementById('flash_message_holder');

    equal(holder.firstChild.style.zIndex, '2');
    equal(holder.firstChild.style.width, '300px');
    equal(holder.firstChild.style.direction, 'rtl');
  });

  test('closes when the close button is clicked', () => {
    helper.initHolder();
    helper.createNode('success', 'Closable Alert');

    let holder = document.getElementById('flash_message_holder');
    let button = holder.getElementsByClassName('close_link');

    equal(button.length, 1);

    $(button[0]).click();

    equal(holder.firstChild, null);
  });

  test('closes when the alert is clicked', () => {
    helper.initHolder();
    helper.createNode('success', 'Closable Alert');

    let holder = document.getElementById('flash_message_holder');
    let alert = holder.getElementsByTagName('LI');

    equal(alert.length, 1);

    $(alert[0]).click();

    equal(holder.firstChild, null);
  });

  module('RailsFlashNotificationsHelper#screenreaderHolderReady', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      helper = new NotificationsHelper();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('returns false if screenreader holder is initialized without the screenreader message holder in the DOM', () => {
    fixtures.innerHTML = '';

    helper.initScreenreaderHolder();

    ok(!helper.screenreaderHolderReady());
  });

  test('returns false before the screenreader holder is initialized even with screenreader message holder in the DOM', () => {
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

    ok(!helper.screenreaderHolderReady());
  });

  test('returns true after the screenreader holder is initialized', () => {
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

    helper.initScreenreaderHolder();

    ok(helper.screenreaderHolderReady());
  });

  module('RailsFlashNotificationsHelper#setScreenreaderAttributes', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

      helper = new NotificationsHelper();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('does not apply attributes if screenreader holder is not initialized', () => {
    helper.setScreenreaderAttributes();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), null);
    equal(screenreaderHolder.getAttribute('aria-live'), null);
    equal(screenreaderHolder.getAttribute('aria-relevant'), null);
  });

  test('applies attributes on initialization of screenreader holder', () => {
    helper.initScreenreaderHolder();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), 'alert');
    equal(screenreaderHolder.getAttribute('aria-live'), 'assertive');
    equal(screenreaderHolder.getAttribute('aria-relevant'), 'additions');
  });

  test('does not break when attributes already exist', () => {
    helper.initScreenreaderHolder();
    helper.setScreenreaderAttributes();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), 'alert');
    equal(screenreaderHolder.getAttribute('aria-live'), 'assertive');
    equal(screenreaderHolder.getAttribute('aria-relevant'), 'additions');
  });

  module('RailsFlashNotificationsHelper#resetScreenreaderAttributes', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

      helper = new NotificationsHelper();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('does not break when the screen reader holder is not initialized', () => {
    helper.resetScreenreaderAttributes();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), null);
    equal(screenreaderHolder.getAttribute('aria-live'), null);
    equal(screenreaderHolder.getAttribute('aria-relevant'), null);
  });

  test('removes attributes from the screenreader holder', () => {
    helper.initScreenreaderHolder();
    helper.resetScreenreaderAttributes();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), null);
    equal(screenreaderHolder.getAttribute('aria-live'), null);
    equal(screenreaderHolder.getAttribute('aria-relevant'), null);
  });

  test('does not break when attributes do not exist', () => {
    helper.initScreenreaderHolder();
    helper.resetScreenreaderAttributes();
    helper.resetScreenreaderAttributes();

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.getAttribute('role'), null);
    equal(screenreaderHolder.getAttribute('aria-live'), null);
    equal(screenreaderHolder.getAttribute('aria-relevant'), null);
  });

  module('RailsFlashNotificationsHelper#generateScreenreaderNodeHTML', {
    setup: function() {
      helper = new NotificationsHelper();
    }
  });

  test('properly injects content into html', () => {
    let result = helper.generateScreenreaderNodeHTML('Some Data');

    ok(result.search("Some Data") !== -1);
  });

  test('properly includes the indication to close when given true', () => {
    let result = helper.generateScreenreaderNodeHTML('Some Data', true);

    ok(result.search(htmlEscape(I18n.t('close', 'Close'))) !== -1);
  });

  test('properly excludes the indication to close when given false', () => {
    let result = helper.generateScreenreaderNodeHTML('Some Data', false);

    ok(result.search(htmlEscape(I18n.t('close', 'Close'))) == -1);
  });

  module('RailsFlashNotificationsHelper#createScreenreaderNode', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

      helper = new NotificationsHelper();
      helper.initScreenreaderHolder();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('creates a screenreader node', () => {
    helper.createScreenreaderNode('Some Other Data');

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.firstChild.tagName, 'SPAN');
  });

  module('RailsFlashNotificationsHelper#createScreenreaderNodeExclusive', {
    setup: function() {
      fixtures = document.getElementById('fixtures');
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>';

      helper = new NotificationsHelper();
      helper.initScreenreaderHolder();
    },
    teardown: function() {
      fixtures.innerHTML = '';
    }
  });

  test('properly clears existing screenreader nodes and creates a new one', () => {
    helper.createScreenreaderNode('Some Data');
    helper.createScreenreaderNode('Some Second Data');
    helper.createScreenreaderNode('Some Third Data');

    let screenreaderHolder = document.getElementById('flash_screenreader_holder');

    equal(screenreaderHolder.childNodes.length, 3);

    helper.createScreenreaderNodeExclusive('Some New Data');

    equal(screenreaderHolder.childNodes.length, 1);
  });

  module('RailsFlashNotificationsHelper#escapeContent', {
    setup: function() {
      helper = new NotificationsHelper();
    }
  });

  test('returns html if content has html property', () => {
    let content = {};
    content.html = '<script>Some Script</script>';

    let result = helper.escapeContent(content);

    equal(result, content.html);
  });

  test('returns html if content has string property', () => {
    let content = {};
    content.string = '<script>Some String</script>';

    let result = helper.escapeContent(content);

    equal(result, content);
  });

  test('returns escaped content if content has no string or html property', () => {
    let content = '<script>Some Data</script>';

    let result = helper.escapeContent(content);

    equal(result, htmlEscape(content));
  });
});