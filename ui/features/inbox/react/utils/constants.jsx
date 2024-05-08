import { createContext } from "react"

export const ModalBodyContext = createContext({
  body: '',
  setBody: (e) => {},
  translating: false,
  setTranslating: (e) => {},
  setTranslationTargetLanguage: (e) => {},
  messagePosition: null,
  setMessagePosition: (e) => {},
  translateBody: (e) => {}
})

export const translationSeparator = "\n\n----------\n\n"
export const signatureSeparator = "\n\n---\n"
