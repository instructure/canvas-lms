define(['i18n!custom_help_link'], function (I18n) {
  const USER_TYPES = [
    { value: 'user', label: I18n.t('Users') },
    { value: 'student', label: I18n.t('Students') },
    { value: 'teacher', label: I18n.t('Teachers') },
    { value: 'admin', label: I18n.t('Admins') }
  ];

  const DEFAULT_LINK = Object.freeze({
    text: '',
    subtext: '',
    url: '',
    available_to: USER_TYPES.map(type => type.value),
    is_default: 'false',
    index: 0,
    state: 'new'
  });

  const NAME_PREFIX = 'account[custom_help_links]'

  return Object.freeze({
    USER_TYPES,
    DEFAULT_LINK,
    NAME_PREFIX
  });
});
