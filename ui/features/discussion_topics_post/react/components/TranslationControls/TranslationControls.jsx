import React, { useContext, useState } from 'react'
import { SimpleSelect } from '@instructure/ui-simple-select';
import { View } from '@instructure/ui-view';
import { DiscussionManagerUtilityContext } from '../../utils/constants';

// TODO: Translate the language controls into the canvas target locale.
export const TranslationControls = () => {
  const heading = `Translate Discussion`
  const { translationLanguages, setTranslateTargetLanguage } = useContext(DiscussionManagerUtilityContext)
  const [language, setLanguage] = useState(translationLanguages.current[0].name)

  const handleSelect = (e, { id, value }) => {
    setLanguage(value)

    // Also set global language in context
    setTranslateTargetLanguage(id)
  }

  return (
    <View as="div" margin="x-small 0 0">
      <SimpleSelect
        renderLabel={heading}
        value={language}
        onChange={handleSelect}
        width='360px'
      >
        {translationLanguages.current.map(({ id, name }) => {
          return (<SimpleSelect.Option
            key={id}
            id={id}
            value={name}>
            {name}
          </SimpleSelect.Option>
          )
        })}
      </SimpleSelect>
    </View>
  )
}
