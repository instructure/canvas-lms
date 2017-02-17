define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Heading }) => {
  const HomeTray = () => (
    <div>
      <Heading tag="h2" level="h1" >{I18n.t('Modules')}</Heading>
    </div>
  );

  return HomeTray;
});
