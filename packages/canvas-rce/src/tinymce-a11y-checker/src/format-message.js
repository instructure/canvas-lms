import formatMessage from "format-message"
import translations from "./translations.json"
import generateId from "format-message-generate-id/underscored_crc32"

const ns = formatMessage.namespace()
ns.setup({ translations, generateId })

export default ns
