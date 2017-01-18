define([
  'react',
  'jsx/shared/KeyboardShortcutModal',
  'i18n!react_files'
], function(React, KeyboardShortcutModal, I18n) {

  var SHORTCUTS = [
    { keycode: 'j', description: I18n.t('Next Message') },
    { keycode: 'k', description: I18n.t('Previous Message') },
    { keycode: 'e', description: I18n.t('Edit Current Message') },
    { keycode: 'd', description: I18n.t('Delete Current Message') },
    { keycode: 'r', description: I18n.t('Reply to Current Message') },
    { keycode: 'n', description: I18n.t('Reply to Topic') }
  ];

  var DiscussionTopicKeyboardShortcutModal = React.createClass({
    render() {
      return <KeyboardShortcutModal {...this.props} shortcuts={SHORTCUTS} />;
    }
  });

  return DiscussionTopicKeyboardShortcutModal;
});
