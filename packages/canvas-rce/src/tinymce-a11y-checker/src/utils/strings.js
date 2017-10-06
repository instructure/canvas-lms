export function filename(url) {
  const pattern = /([^\/]*?)(\?.*)?$/
  const result = pattern.exec(url)
  return result && result[1]
}

export function firstWords(text, num) {
  const pattern = /\w+/g
  const words = []
  let result
  while (num > 0 && (result = pattern.exec(text))) {
    --num
    words.push(result[0])
  }
  let ret = words.join(" ")
  if (result != null && pattern.exec(text)) {
    ret += "…"
  }
  return ret
}
