#!/usr/bin/env node

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

/*
 * This script is used for generating the SVGs that are used on the math
 * symbol buttons in the new equation editor of the RCE. It will create
 * an SVG for each button and stores them in an JS object located at OUTPUT_PATH.
 *
 * The buttons object we import comes from an ES module so we need to
 * transpile it to CommonJS before we can use it here. Thus, you need to run
 * the build.js script before this one in order for it to work. Running this
 * script with 'yarn generate-svgs' in the packages/canvas-rce directory
 * handles this for you and is the recommended way to generate these SVGs.
 */

const fs = require('fs')
const mathjax = require('mathjax')

const buttons =
  require('../es/rce/plugins/instructure_equation/EquationEditorToolbar/buttons')

const OUTPUT_PATH = 'src/rce/plugins/instructure_equation/MathIcon/svgs.js'
const SVGS_TEMPLATE = `/*
* Copyright (C) 2022 - present Instructure, Inc.
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


/***** This is an auto-generated file. Please do not modify manually *****/
/************ If you need to update, run 'yarn generate-svgs' ************/

export default __SVG__CONTENT__`

const svgs = {}

let ready = false
let latexToSvg = () => {}

const setupOptions = {
  loader: {
    load: ['input/tex', 'output/svg'],
  },
}

const generateSvg = async latex => {
  if (!ready) {
    const MathJax = await mathjax.init(setupOptions)
    latexToSvg = latexToConvert =>
      MathJax.startup.adaptor.innerHTML(MathJax.tex2svg(latexToConvert))
    ready = true
  }

  return latexToSvg(latex)
}

const convertSection = section => {
  const commandPromises = section.commands.map(async ({command, svgCommand}) => {
    const commandForSvgRender = svgCommand || command
    const svg = await generateSvg(commandForSvgRender)
    svgs[command] = svg
  })

  return Promise.all(commandPromises)
}

const sectionPromises = buttons.map(async section => convertSection(section))

// eslint-disable-next-line promise/catch-or-return
Promise.all(sectionPromises).then(() => {
  const finalOutput = SVGS_TEMPLATE.replace('__SVG__CONTENT__', JSON.stringify(svgs, null, 2))
  fs.writeFileSync(OUTPUT_PATH, finalOutput, {flag: 'w'})
})
