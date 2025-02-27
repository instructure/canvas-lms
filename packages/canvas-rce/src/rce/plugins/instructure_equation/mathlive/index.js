/*
* Copyright (c) 2017 - present Arno Gourdol. All rights reserved.

* Permission is hereby granted, free of charge, to any person obtaining a
* copy of this software and associated documentation files (the "Software"),
* to deal in the Software without restriction, including without limitation
* the rights to use, copy, modify, merge, publish, distribute, sublicense,
* and/or sell copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following conditions:

* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.

* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
* DEALINGS IN THE SOFTWARE.
 */

// TODO: restore import after switch from webpack to rslib
// import mathliveCss from 'mathlive/dist/mathlive-fonts.css'

const mathliveCss = `
@font-face {
  font-display: "swap";
  font-family: KaTeX_AMS;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_AMS-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Caligraphic;
  font-style: normal;
  font-weight: 700;
  src: url(fonts/KaTeX_Caligraphic-Bold.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Caligraphic;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Caligraphic-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Fraktur;
  font-style: normal;
  font-weight: 700;
  src: url(fonts/KaTeX_Fraktur-Bold.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Fraktur;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Fraktur-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Main;
  font-style: italic;
  font-weight: 700;
  src: url(fonts/KaTeX_Main-BoldItalic.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Main;
  font-style: normal;
  font-weight: 700;
  src: url(fonts/KaTeX_Main-Bold.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Main;
  font-style: italic;
  font-weight: 400;
  src: url(fonts/KaTeX_Main-Italic.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Main;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Main-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Math;
  font-style: italic;
  font-weight: 700;
  src: url(fonts/KaTeX_Math-BoldItalic.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Math;
  font-style: italic;
  font-weight: 400;
  src: url(fonts/KaTeX_Math-Italic.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: "KaTeX_SansSerif";
  font-style: normal;
  font-weight: 700;
  src: url(fonts/KaTeX_SansSerif-Bold.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: "KaTeX_SansSerif";
  font-style: italic;
  font-weight: 400;
  src: url(fonts/KaTeX_SansSerif-Italic.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: "KaTeX_SansSerif";
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_SansSerif-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Script;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Script-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Size1;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Size1-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Size2;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Size2-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Size3;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Size3-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Size4;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Size4-Regular.woff2) format("woff2");
}
@font-face {
  font-display: "swap";
  font-family: KaTeX_Typewriter;
  font-style: normal;
  font-weight: 400;
  src: url(fonts/KaTeX_Typewriter-Regular.woff2) format("woff2");
}
:root {
  --ML__static-fonts: true;
}
`

const cssRules = `.ML__popover {
  /* Override this so it shows up on top of dialogs */
  z-index: 20000 !important;
}`

const style = document.createElement('style')
style.appendChild(document.createTextNode(mathliveCss))
style.appendChild(document.createTextNode(cssRules))
document.head.appendChild(style)

export * from 'mathlive'
