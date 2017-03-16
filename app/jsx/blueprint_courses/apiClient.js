import axios from 'axios'

const ApiClient = {
  toggleLocked ({ courseId, itemType, itemId, isLocked }) {
    return axios.put(`/api/v1/courses/${courseId}/blueprint_templates/default/restrict_item`, {
      content_type: itemType,
      content_id: itemId,
      restricted: isLocked,
    })
  }
}

export default ApiClient
