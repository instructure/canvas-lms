import initStoryshots, { renderWithOptions } from '@storybook/addon-storyshots'
import { render } from "@testing-library/react";

// Since the Storybook Hierarchy is "Examples/<Category>/<Component>"
//  add <Category> for snapshot testing here
const STORY_KIND = ['Outcomes']

initStoryshots({
  storyKindRegex: new RegExp(`Examples/(${STORY_KIND.join('|')})`),
  test: renderWithOptions({ renderer: render })
})

