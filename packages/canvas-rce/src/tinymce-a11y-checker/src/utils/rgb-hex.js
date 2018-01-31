/**
 * This file is taken from the rgb-hex npm module to ensure it is transpiled.
 */
"use strict"
/* eslint-disable no-mixed-operators */
module.exports = (red, green, blue, alpha) => {
  const isPercent = (red + (alpha || "")).toString().includes("%")

  if (typeof red === "string") {
    const res = red.match(/(0?\.?\d{1,3})%?\b/g).map(Number)
    // TODO: use destructuring when targeting Node.js 6
    red = res[0]
    green = res[1]
    blue = res[2]
    alpha = res[3]
  } else if (alpha !== undefined) {
    alpha = parseFloat(alpha)
  }

  if (
    typeof red !== "number" ||
    typeof green !== "number" ||
    typeof blue !== "number" ||
    red > 255 ||
    green > 255 ||
    blue > 255
  ) {
    throw new TypeError("Expected three numbers below 256")
  }

  if (typeof alpha === "number") {
    if (!isPercent && alpha >= 0 && alpha <= 1) {
      alpha = Math.round(255 * alpha)
    } else if (isPercent && alpha >= 0 && alpha <= 100) {
      alpha = Math.round(255 * alpha / 100)
    } else {
      throw new TypeError(
        `Expected alpha value (${alpha}) as a fraction or percentage`
      )
    }
    alpha = (alpha | (1 << 8)).toString(16).slice(1)
  } else {
    alpha = ""
  }

  return (
    (blue | (green << 8) | (red << 16) | (1 << 24)).toString(16).slice(1) +
    alpha
  )
}
