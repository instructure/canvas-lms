import offset from "bloody-offset"

const MARGIN = 3

export function indicatorRegion(
  editorFrame,
  target,
  offsetFn = offset,
  boundingRectOverride
) {
  const outerShape = offsetFn(editorFrame)
  const b = boundingRectOverride || target.getBoundingClientRect()
  const innerShape = {
    top: b.top,
    left: b.left,
    width: b.right - b.left,
    height: b.bottom - b.top
  }

  return {
    width: innerShape.width,
    height: innerShape.height,
    left: outerShape.left + innerShape.left,
    top: outerShape.top + innerShape.top
  }
}

export default function indicate(editor, elem, margin = MARGIN) {
  document
    .querySelectorAll(".a11y-checker-selection-indicator")
    .forEach(existingElem => {
      existingElem.parentNode.removeChild(existingElem)
    })

  const editorFrame = editor.getContainer().querySelector("iframe")

  const el = document.createElement("div")
  el.className = "a11y-checker-selection-indicator"

  const region = indicatorRegion(editorFrame, elem)

  el.setAttribute(
    "style",
    `
    border: 2px solid #000;
    background-color: #008EE2;
    position: absolute;
    display: block;
    borderRadius: 5px;
    zIndex: 999999;
    left: ${region.left - margin}px;
    top: ${region.top - margin}px;
    width: ${region.width + 2 * margin}px;
    height: ${region.height + 2 * margin}px;
    opacity: 0.5;
  `
  )

  document.body.appendChild(el)

  el.style.opacity = 0.8
  el.style.transition = "opacity 0.4s"

  const adjust = () => {
    const boundingRect = elem.getBoundingClientRect()
    const region = indicatorRegion(editorFrame, elem, offset, boundingRect)
    const editorFrameOffset = offset(editorFrame)
    el.style.left = `${region.left - margin}px`
    el.style.top = `${region.top - margin}px`
    el.style.display = "block"
    if (boundingRect.top < 0) {
      const newHeight = region.height + boundingRect.top
      if (newHeight < 0) {
        el.style.display = "none"
      }
      const newTop = region.height - newHeight
      el.style.height = `${newHeight}px`
      el.style.marginTop = `${newTop}px`
    }
    if (boundingRect.bottom > editorFrameOffset.height) {
      const newHeight =
        region.height + (editorFrameOffset.height - boundingRect.bottom)
      if (newHeight < 0) {
        el.style.display = "none"
      }
      el.style.height = `${newHeight}px`
    }
    window.requestAnimationFrame(adjust)
  }

  window.requestAnimationFrame(adjust)
}
