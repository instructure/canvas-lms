#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module ContextModulesHelper
  def cache_if_module(context_module, editable, draft_state, &block)
    if context_module
      cache(['context_module_render_3_', context_module.cache_key, editable, draft_state].join('/'), nil, &block)
    else
      yield
    end
  end

  def module_item_published?(item)
    # If I publish an attachment, but its folder is hidden, the file is still
    # hidden, now what? WHAT DO WE DO?
    item && ((item.content && item.content.respond_to?(:published?)) ? item.content : item).published?
  end

  def module_item_publishable_id(item)
    if item.nil?
      ''
    elsif (item.content_type_class == 'wiki_page')
      item.content.url
    else
      (item.content && item.content.respond_to?(:published?) ? item.content.id : item.id)
    end
  end

  def module_item_publishable?(item)
    return true if item.nil? || !item.content
    content_type_class = item.content_type_class
    if (content_type_class == 'attachment')
      # don't know how to publish/unpublish attachments yet
      false
    elsif (content_type_class == 'quiz')
      # quizzes can't be unpublished once they have been published and
      # taken by at least one person (maybe this should be abstracted
      # elsewhere?) also, I know this is probably bad for the db.
      item.content.quiz_submissions.count == 0
    elsif (content_type_class == 'discussion_topic')
      # don't know what this means for discussions yet really
      #item.content.can_unpublish?
      false
    else
      true
    end
  end

end
