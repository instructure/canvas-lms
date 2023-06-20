/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {getThemeVars} from '../../getThemeVars'

export default function buildStyle() {
  /*
   * If the theme variables to be used when generating the styles below
   * are dependent on the actual theme in use, you can also pull out the
   * `key` property from the return from `getThemeVars()` and do a bit of
   * if or switch statement logic to get the result you want.
   */
  const {variables, key} = getThemeVars()

  let themeAdditionalStyles = {}
  switch (key) {
    case 'canvas':
      themeAdditionalStyles = {
        iconColor: variables['ic-brand-primary'],
      }
      break
  }

  const classNames = {
    root: 'PlannerItem-styles__root',
    small: 'PlannerItem-styles__small',
    medium: 'PlannerItem-styles__medium',
    k5: 'PlannerItem-styles__k5',
    k5Layout: 'PlannerItem-styles__k5Layout',
    missingItem: 'PlannerItem-styles__missingItem',
    completed: 'PlannerItem-styles__completed',
    avatar: 'PlannerItem-styles__avatar',
    icon: 'PlannerItem-styles__icon',
    layout: 'PlannerItem-styles__layout',
    innerLayout: 'PlannerItem-styles__innerLayout',
    details: 'PlannerItem-styles__details',
    details_no_badges: 'PlannerItem-styles__details_no_badges',
    secondary: 'PlannerItem-styles__secondary',
    secondary_no_badges: 'PlannerItem-styles__secondary_no_badges',
    type: 'PlannerItem-styles__type',
    title: 'PlannerItem-styles__title',
    metrics: 'PlannerItem-styles__metrics',
    with_end_time: 'PlannerItem-styles__with_end_time',
    due: 'PlannerItem-styles__due',
    score: 'PlannerItem-styles__score',
    badges: 'PlannerItem-styles__badges',
    feedback: 'PlannerItem-styles__feedback',
    feedbackAvatar: 'PlannerItem-styles__feedbackAvatar',
    feedbackComment: 'PlannerItem-styles__feedbackComment',
    location: 'PlannerItem-styles__location',
    moreDetails: 'PlannerItem-styles__moreDetails',
    activityIndicator: 'PlannerItem-styles__activityIndicator',
    editButton: 'PlannerItem-styles__editButton',
  }

  const theme = {
    lineHeight: variables.typography.lineHeightCondensed,
    color: variables.colors.licorice,
    secondaryColor: variables.colors.ash,
    padding: `${variables.spacing.small} ${variables.spacing.xSmall}`,
    paddingMedium: `${variables.spacing.small}`,
    paddingLarge: `${variables.spacing.small} ${variables.spacing.medium}`,
    gutterWidth: variables.spacing.medium,
    gutterWidthXLarge: variables.spacing.medium,
    bottomMargin: variables.spacing.xSmall,
    borderWidth: variables.borders.widthSmall,
    borderColor: variables.colors.tiara,
    iconFontSize: variables.spacing.medium,
    iconColor: variables.colors.brand,
    badgeMargin: '0.0625rem',
    metricsPadding: variables.spacing.xxSmall,
    typeMargin: variables.spacing.xxSmall,
    titleLineHeight: variables.typography.lineHeightFit,
    ...themeAdditionalStyles,
  }

  const css = `
  .${classNames.root} {
    font-family: ${theme.fontFamily};
    box-sizing: border-box;
    padding: ${theme.padding};
    border-bottom: ${theme.borderWidth} solid ${theme.borderColor};
    flex: 1;
    display: flex;
    align-items: center;
    color: ${theme.color};
    line-height: ${theme.lineHeight};
  }
  .${classNames.root}.${classNames.small} {
    align-items: flex-start;
  }
  .${classNames.root}.${classNames.small}.${classNames.k5Layout} {
    align-items: center;
  }
  .${classNames.root}.${classNames.small}.${classNames.k5Layout} > .${classNames.icon} {
    display: block;
    margin: 0 0 0 0.5rem;
  }
  .${classNames.root}.${classNames.small}.${classNames.k5Layout} > .${classNames.layout} .${classNames.details} {
    margin-bottom: 0;
  }
  .${classNames.root}.${classNames.small}.${classNames.missingItem} {
    padding-inline-start: 0;
  }
  .${classNames.root}.${classNames.missingItem} {
    padding-inline-start: 0.5rem;
    padding-inline-end: 0;
  }
  
  .${classNames.completed},
  .${classNames.avatar},
  .${classNames.icon},
  .${classNames.layout} {
    box-sizing: border-box;
  }
  
  .${classNames.completed} {
    width: 1.375rem;
    margin-inline-start: ${theme.gutterWidth};
  }
  
  .${classNames.activityIndicator} {
    padding-inline-end: 0;
    padding-inline-start: 0;
  }
  
  .${classNames.activityIndicator} + .${classNames.completed} {
    margin-inline-start: calc(${theme.gutterWidth} - ${theme.activityIndicatorWidth});
  }
  
  .${classNames.icon} {
    color: ${theme.iconColor};
    margin: 0 ${theme.gutterWidth};
  }
  .${classNames.icon} > svg {
    /* stylelint-disable-line selector-no-type */
    display: block;
  }
  
  .${classNames.avatar} {
    /* adjust margin so <Avatar size="small"> fits in same space as the icon */
    margin: 0 calc(${theme.gutterWidth} - ((1em * 2.5) - ${theme.iconFontSize}) / 2);
  }
  
  .${classNames.layout} {
    display: flex;
    flex-direction: column;
    flex: 1 0;
    min-width: 1px;
  }
  
  .${classNames.innerLayout} {
    display: flex;
    flex: 1 0;
    align-items: center;
    min-width: 1px;
    min-height: 2.5rem;
    /* or ie11 smashes it down */
  }
  
  .${classNames.details} {
    flex: 0 0 50%;
    margin-bottom: 0;
    box-sizing: border-box;
    min-width: 1px;
  }
  .${classNames.details}.${classNames.details_no_badges} {
    flex: 0 0 75%;
  }
  
  .${classNames.secondary} {
    flex: 0 0 50%;
    box-sizing: border-box;
    display: flex;
    align-items: center;
    justify-content: flex-end;
    min-width: 1px;
  }
  .${classNames.secondary}.${classNames.secondary_no_badges} {
    flex: 0 0 25%;
  }
  
  .${classNames.type} {
    box-sizing: border-box;
    line-height: 1;
    text-transform: uppercase;
    letter-spacing: 0.0625rem;
    margin-bottom: ${theme.typeMargin};
  }
  
  .${classNames.title} {
    box-sizing: border-box;
    line-height: ${theme.titleLineHeight};
  }
  
  .${classNames.metrics} {
    box-sizing: border-box;
    text-align: end;
    flex: 0 0 10rem;
    min-width: 1px;
    padding-inline-start: ${theme.metricsPadding};
  }
  .${classNames.metrics}.${classNames.with_end_time} {
    flex-basis: 14rem;
  }
  .${classNames.metrics}.${classNames.with_end_time} .${classNames.due} {
    text-transform: none;
  }
  .${classNames.missingItem} .${classNames.metrics} {
    flex-basis: 16rem;
  }
  .${classNames.missingItem} .${classNames.metrics}.${classNames.with_end_time} {
    flex-basis: 20rem;
  }
  
  .${classNames.due},
  .${classNames.score} {
    color: ${theme.secondaryColor};
    box-sizing: border-box;
    text-transform: uppercase;
    letter-spacing: 0.0625rem;
    line-height: 1;
    white-space: nowrap;
  }
  
  .${classNames.badges} {
    flex: 1;
    text-align: end;
    min-width: 1px;
  }
  
  .${classNames.feedback} {
    display: flex;
    align-items: center;
    min-height: 40px;
    /* height of the avater, so ie11 doesn't squish it */
  }
  .${classNames.feedback} .${classNames.feedbackAvatar} {
    flex-shrink: 0;
    margin-inline-end: ${theme.gutterWidth};
  }
  .${classNames.feedback} .${classNames.feedbackComment} {
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
  
  .${classNames.location} {
    text-overflow: ellipsis;
    overflow: hidden;
  }
  
  .${classNames.small} .${classNames.title},
  .${classNames.medium} .${classNames.title} {
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    padding-inline-end: 0.5rem;
  }
  
  .${classNames.small} {
    padding-left: 0;
    padding-right: 0;
  }
  .${classNames.small} .${classNames.completed} {
    margin-inline-start: 6px;
  }
  .${classNames.small} .${classNames.innerLayout} {
    flex-direction: column;
    align-items: flex-start;
    margin-inline-start: 1rem;
  }
  .${classNames.small} .${classNames.details} {
    margin-bottom: 1rem;
    flex: 1 0 auto;
    width: 100%;
  }
  .${classNames.small} .${classNames.moreDetails} {
    display: flex;
    justify-content: space-between;
  }
  .${classNames.small} .${classNames.secondary} {
    flex: 1 0 auto;
    width: 100%;
  }
  .${classNames.small} .${classNames.metrics} {
    display: flex;
    flex-direction: row-reverse;
    justify-content: space-between;
    align-items: flex-end;
    flex: 1 0 auto;
    text-align: unset;
    padding-inline-start: 0;
  }
  .${classNames.small} .${classNames.due} {
    width: 100%;
  }
  .${classNames.small} .${classNames.icon},
  .${classNames.small} .${classNames.avatar},
  .${classNames.small} .${classNames.badges},
  .${classNames.small} .${classNames.feedback},
  .${classNames.small} .${classNames.editButton} {
    display: none;
  }
  .${classNames.small} .${classNames.location} {
    color: ${theme.secondaryColor};
    margin-inline-start: 1rem;
  }
  
  :global(.${classNames.k5}) .type {
    display: none;
  }
  `

  return {css, classNames, theme}
}
