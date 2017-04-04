import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Heading from 'instructure-ui/lib/components/Heading'
import Typography from 'instructure-ui/lib/components/Typography'
import SVGWrapper from 'jsx/shared/SVGWrapper'

  const ModulesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Modules')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Organize your course content')}
      </Typography>
      <Typography as="p">
        {
            I18n.t(`Organize and segment your course by topic, unit, chapter,
                    or week. Sequence select modules by defining criteria and
                    prerequisites.`)
          }
      </Typography>
      <div className="NewUserTutorialTray__ImageContainer" aria-hidden="true">
        <SVGWrapper url="/images/tutorial-tray-images/module_tutorial.svg" />
      </div>
    </div>
  );

export default ModulesTray
