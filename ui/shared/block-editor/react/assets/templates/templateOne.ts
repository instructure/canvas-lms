/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export const templateOne = {
  ROOT: {
    type: {
      resolvedName: 'PageBlock',
    },
    isCanvas: true,
    props: {},
    displayName: 'Page',
    custom: {},
    hidden: false,
    nodes: ['ftVtiCUI_K', 'rXCSp2TzpG', 'Q5FJbp_nx0', 'hg7VcyyOiz', 'tXFIeZJxP0'],
    linkedNodes: {},
  },
  ftVtiCUI_K: {
    type: {
      resolvedName: 'HeroSection',
    },
    isCanvas: false,
    props: {
      background: '#f9faff',
    },
    displayName: 'Hero',
    custom: {
      isSection: true,
    },
    parent: 'ROOT',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'hero-section_nosection1': 'TFTTybCaAT',
      'hero-section_nosection2': 'QvgT9JPBaT',
    },
  },
  TFTTybCaAT: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'hero-section__inner-start',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'ftVtiCUI_K',
    hidden: false,
    nodes: ['ZODdPQOlw9'],
    linkedNodes: {},
  },
  ZODdPQOlw9: {
    type: {
      resolvedName: 'HeroTextHalf',
    },
    isCanvas: true,
    props: {
      id: 'hero-section_text',
      color: '#2d3b45',
    },
    displayName: 'Hero Text',
    custom: {
      noToolbar: true,
    },
    parent: 'TFTTybCaAT',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'hero-section_text__no-section': '2j86G5Fu6D',
    },
  },
  '2j86G5Fu6D': {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'text-half__inner',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'ZODdPQOlw9',
    hidden: false,
    nodes: ['JkDTjDAKDv', 'lf9sIOp0xH', '6w7BQbw3sM'],
    linkedNodes: {},
  },
  JkDTjDAKDv: {
    type: {
      resolvedName: 'HeadingBlock',
    },
    isCanvas: false,
    props: {
      level: 'h2',
      id: 'hero-section_text__title',
      text: 'Welcome to Class!',
    },
    displayName: 'Heading',
    custom: {
      themeOverride: {
        h2FontFamily: 'Georgia, LatoWeb, Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
        h2FontSize: '4rem',
        h2FontWeight: 'bold',
        primaryColor: '#2d3b45',
      },
    },
    parent: '2j86G5Fu6D',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  lf9sIOp0xH: {
    type: {
      resolvedName: 'TextBlock',
    },
    isCanvas: false,
    props: {
      fontSize: '12pt',
      textAlign: 'start',
      color: '#2d3b45',
      id: 'hero-section_text__text',
      text: "It's going to be a great year of learning new things and making memories with your classmates!<br><br>",
    },
    displayName: 'Text',
    custom: {},
    parent: '2j86G5Fu6D',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  '6w7BQbw3sM': {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Start Here',
      href: '#',
      size: 'medium',
      variant: 'filled',
      color: '#85a9ff33',
      id: 'hero-section_text__link',
    },
    displayName: 'Button',
    custom: {},
    parent: '2j86G5Fu6D',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  QvgT9JPBaT: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'hero-section__inner-end',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'ftVtiCUI_K',
    hidden: false,
    nodes: ['OuvSAcbSnM'],
    linkedNodes: {},
  },
  OuvSAcbSnM: {
    type: {
      resolvedName: 'ImageBlock',
    },
    isCanvas: true,
    props: {
      imageSrc: '',
      variant: 'default',
      constraint: 'contain',
      id: 'hero-section_image',
      src: '/images/block_editor/hero-image2.svg',
    },
    displayName: 'Image',
    custom: {},
    parent: 'QvgT9JPBaT',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  rXCSp2TzpG: {
    type: {
      resolvedName: 'NavigationSection',
    },
    isCanvas: false,
    props: {
      background: '#334870',
    },
    displayName: 'Navigation',
    custom: {
      isSection: true,
    },
    parent: 'ROOT',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'navigation-section__inner': 'o-y7Qs08R_',
    },
  },
  'o-y7Qs08R_': {
    type: {
      resolvedName: 'NavigationSectionInner',
    },
    isCanvas: true,
    props: {},
    displayName: 'Navigation',
    custom: {
      noToolbar: true,
    },
    parent: 'rXCSp2TzpG',
    hidden: false,
    nodes: ['m3Ag2x_oIa', '4H98X8EUrc', 'cKcYDmc7PH', '8hCHy7yZmO', 'xWV-5j_tqu'],
    linkedNodes: {},
  },
  m3Ag2x_oIa: {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Home',
      href: '../',
      size: 'medium',
      variant: 'condensed',
      color: 'primary-inverse',
      id: 'navigation-section_link1',
      iconName: 'apple',
    },
    displayName: 'Button',
    custom: {},
    parent: 'o-y7Qs08R_',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  cKcYDmc7PH: {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Modules',
      href: '../modules',
      size: 'medium',
      variant: 'condensed',
      color: 'primary-inverse',
      id: 'navigation-section_link2',
      iconName: 'video',
    },
    displayName: 'Button',
    custom: {},
    parent: 'o-y7Qs08R_',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  '8hCHy7yZmO': {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Grades',
      href: '../grades',
      size: 'medium',
      variant: 'condensed',
      color: 'primary-inverse',
      id: 'navigation-section_link3',
      iconName: 'module',
    },
    displayName: 'Button',
    custom: {},
    parent: 'o-y7Qs08R_',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  'xWV-5j_tqu': {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Resources',
      href: '../resources',
      size: 'medium',
      variant: 'condensed',
      color: 'primary-inverse',
      id: 'navigation-section_link4',
      iconName: 'briefcase',
    },
    displayName: 'Button',
    custom: {},
    parent: 'o-y7Qs08R_',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  Q5FJbp_nx0: {
    type: {
      resolvedName: 'AnnouncementSection',
    },
    isCanvas: false,
    props: {
      announcementId: '1',
    },
    displayName: 'Announcement',
    custom: {
      isSection: true,
    },
    parent: 'ROOT',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  hg7VcyyOiz: {
    type: {
      resolvedName: 'AboutSection',
    },
    isCanvas: false,
    props: {
      background: '#f9faff',
    },
    displayName: 'About',
    custom: {
      isSection: true,
    },
    parent: 'ROOT',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'about-section_about-nosection1': 'jyicoKs7qk',
      'about-section_about-no-section2': 'YrwdgUaTRG',
    },
  },
  jyicoKs7qk: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'about-section__inner-end',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'hg7VcyyOiz',
    hidden: false,
    nodes: ['LzyysA_swe'],
    linkedNodes: {},
  },
  LzyysA_swe: {
    type: {
      resolvedName: 'ImageBlock',
    },
    isCanvas: true,
    props: {
      imageSrc: '',
      variant: 'default',
      constraint: 'contain',
      id: 'about-section_image',
      src: '/images/block_editor/about-image2.png',
    },
    displayName: 'Image',
    custom: {},
    parent: 'jyicoKs7qk',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  YrwdgUaTRG: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'about-section__inner-start',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'hg7VcyyOiz',
    hidden: false,
    nodes: ['konjDVAaZJ'],
    linkedNodes: {},
  },
  konjDVAaZJ: {
    type: {
      resolvedName: 'AboutTextHalf',
    },
    isCanvas: true,
    props: {
      id: 'about-section_text',
      color: '#2d3b45',
    },
    displayName: 'About Text',
    custom: {},
    parent: 'YrwdgUaTRG',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'about-section_text__no-section': 'I8oiXTLl0M',
    },
  },
  I8oiXTLl0M: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'text-half__inner',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'konjDVAaZJ',
    hidden: false,
    nodes: ['2L-ALGn5zs', 'DS_wWUEKzS'],
    linkedNodes: {},
  },
  '2L-ALGn5zs': {
    type: {
      resolvedName: 'HeadingBlock',
    },
    isCanvas: false,
    props: {
      level: 'h2',
      id: 'about-section_text__title',
      text: "Teacher's Note",
    },
    displayName: 'Heading',
    custom: {
      themeOverride: {
        h2FontFamily: 'Georgia, LatoWeb, Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
        h2FontWeight: 'bold',
        h2FontSize: '1.25rem',
        primaryColor: '#2d3b45',
      },
    },
    parent: 'I8oiXTLl0M',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  DS_wWUEKzS: {
    type: {
      resolvedName: 'TextBlock',
    },
    isCanvas: false,
    props: {
      fontSize: '12pt',
      textAlign: 'start',
      color: '#2d3b45',
      id: 'about-section_text__text',
      text: '<span data-metadata="<!--(figmeta)eyJmaWxlS2V5IjoiaFN2UVlyZENhMW54RThNYldzOVh2OCIsInBhc3RlSUQiOjEzMTczMDI4OTAsImRhdGFUeXBlIjoic2NlbmUifQo=(/figmeta)-->" style="caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);"></span><span data-buffer="<!--(figma)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(/figma)-->" style="caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);"></span><span style="white-space: pre-wrap; caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);">In our classroom, we value kindness, respect, and cooperation. Each one of you brings something unique to our classroom community, and I encourage you to always be yourself and embrace your individuality.</span><div><span style="white-space: pre-wrap; caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);"><br>Throughout the year, we will dive into various subjects such as math, science, reading, writing, and social studies. I believe that learning should be engaging and enjoyable, so get ready for hands-on activities, group projects, and stimulating discussions.</span></div><div><span style="white-space: pre-wrap; caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);"><br>I want you to know that my door is always open for you. Whether you have questions, concerns, or just want to share something exciting, I am here to listen and support you every step of the way.</span></div><div><span style="white-space: pre-wrap; caret-color: rgb(0, 0, 0); color: rgb(0, 0, 0);"><br>Together, we will create unforgettable memories and achieve great things. I am confident that this school year will be filled with success and accomplishment.</span><br></div>',
    },
    displayName: 'Text',
    custom: {
      displayName: 'About Text',
    },
    parent: 'I8oiXTLl0M',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  '4H98X8EUrc': {
    type: {
      resolvedName: 'ButtonBlock',
    },
    isCanvas: false,
    props: {
      text: 'Schedule',
      href: '../calendar',
      size: 'medium',
      variant: 'condensed',
      color: 'primary-inverse',
      iconName: 'calendar',
    },
    displayName: 'Button',
    custom: {},
    parent: 'o-y7Qs08R_',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  'SuNnbPx-g5': {
    type: {
      resolvedName: 'ImageBlock',
    },
    isCanvas: true,
    props: {
      imageSrc: '',
      variant: 'default',
      constraint: 'cover',
      id: 'hero-section__footer-canvas-icon',
      src: '/images/block_editor/canvas_logo_white.svg',
      width: 113,
      height: 28,
    },
    displayName: 'Image',
    custom: {},
    parent: 'bD1vrkQK2M',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
  bD1vrkQK2M: {
    type: {
      resolvedName: 'NoSections',
    },
    isCanvas: true,
    props: {
      className: 'footer-section__inner',
    },
    displayName: 'Column',
    custom: {
      noToolbar: true,
    },
    parent: 'tXFIeZJxP0',
    hidden: false,
    nodes: ['SuNnbPx-g5', 'OFr82Vq31Y'],
    linkedNodes: {},
  },
  tXFIeZJxP0: {
    type: {
      resolvedName: 'FooterSection',
    },
    isCanvas: false,
    props: {
      background: '#0A0189',
    },
    displayName: 'Footer',
    custom: {
      isSection: true,
    },
    parent: 'ROOT',
    hidden: false,
    nodes: [],
    linkedNodes: {
      'hero-section__footer-no-section': 'bD1vrkQK2M',
    },
  },
  OFr82Vq31Y: {
    type: {
      resolvedName: 'TextBlock',
    },
    isCanvas: false,
    props: {
      fontSize: '14pt',
      textAlign: 'start',
      color: 'var(--ic-brand-font-color-dark)',
      text: '<p></p><p style="color: white;"><span style="text-wrap-mode: wrap;">Grade 4 Elementary</span></p><p style="color: white;"><span style="font-size: 12pt; text-wrap-mode: wrap;">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 2024</span><br></p><span style="font-weight: bold;"><p style="font-weight: normal;"></p></span><p></p>',
    },
    displayName: 'Text',
    custom: {},
    parent: 'bD1vrkQK2M',
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
}
