# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module ContentNotices
  NOTICE_ATTRIBUTES = %i[tag text variant link_text link_target should_show].freeze

  class ContentNotice
    attr_accessor(*NOTICE_ATTRIBUTES)
  end

  module ClassMethods
    #  opts must include:
    #    text: string (or Proc that returns string): text for the notice
    #  opts may optionally contain:
    #    variant: string: InstUI alert variant ('info', 'success', 'error', 'warning'; default is 'info')
    #    link_text: string (or Proc that returns string): text for a link that follows the notice
    #    link_target: string (or Proc that takes the context and returns a string): the target for said link
    #    should_show: Proc: callback that receives the context and user, and returns whether the notice should be displayed
    # see course.rb for example usage
    def define_content_notice(tag, opts)
      notice = ContentNotice.new
      NOTICE_ATTRIBUTES.each do |attr|
        notice.instance_variable_set :"@#{attr}", opts[attr] if opts.include?(attr)
      end
      notice.tag ||= tag
      @content_notices ||= {}
      @content_notices[tag] = notice
    end

    def content_notices
      @content_notices
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def cn_cache_key(tag)
    ["content_notice_present", tag, asset_string].cache_key
  end

  # add a notice to this context. if the notice with the given tag is already active for the context,
  # its expiration time will be reset.
  def add_content_notice(tag, expires_in = nil)
    Rails.cache.write(cn_cache_key(tag), true, expires_in:)
  end

  # remove a notice from this context
  def remove_content_notice(tag)
    Rails.cache.delete(cn_cache_key(tag))
  end

  # return an array of content notices that should be shown to the user
  def content_notices(user)
    self.class.content_notices.select do |tag, notice|
      Rails.cache.read(cn_cache_key(tag)) && (notice.should_show.nil? || notice.should_show.call(self, user))
    end.values
  end
end
