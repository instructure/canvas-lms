# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class Accessibility::AiGenerationService
  include LocaleSelection
  include Accessibility::NokogiriMethods

  class InvalidParameterError < StandardError; end

  AI_ALT_TEXT_TYPE = "Base64"
  AI_ALT_TEXT_FEATURE_FLAG_SLUG = "alttext"
  AI_ALT_TEXT_MAX_LENGTH = 200
  AI_ALT_TEXT_MAX_IMAGE_SIZE = 10.megabytes
  AI_ALT_TEXT_SUPPORTED_IMAGE_TYPES = Attachment.valid_content_types_hash.select { |_, type| type == "image" }.keys.freeze
  FILE_LINK_REGEX = %r{\A(?!//).*?/files/(\d+)(?:[/?]|$)}

  def initialize(content_type:, content_id:, path:, context:, current_user:, domain_root_account:)
    @content_type = content_type
    @content_id = content_id
    @path = path
    @context = context
    @current_user = current_user
    @domain_root_account = domain_root_account
  end

  def generate_alt_text
    attachment = assume_attachment
    call_cedar_alt_text_generation(attachment)
  end

  def self.extract_attachment_id_from_element(elem)
    return nil unless elem

    src = elem.respond_to?(:get_attribute) ? elem.get_attribute("src") : elem["src"]
    return nil if src.blank?

    match = src.match(FILE_LINK_REGEX)
    match&.captures&.first
  end

  private

  def assume_attachment
    validate_parameters!

    resource = find_resource
    html_content = extract_html_content(resource)

    element = find_element_at_path(html_content, @path)
    attachment_id = extract_and_validate_attachment_id!(element)

    load_and_validate_attachment(attachment_id)
  end

  def validate_parameters!
    errors = []
    errors << "content_type" if @content_type.blank?
    errors << "content_id" if @content_id.blank?
    errors << "path" if @path.blank?

    raise InvalidParameterError if errors.any? || !/\A\d+\z/.match?(@content_id.to_s)
  end

  def find_resource
    Accessibility::Issue.find_resource(@context, @content_type, @content_id)
  rescue ArgumentError, ActiveRecord::RecordNotFound
    raise InvalidParameterError
  end

  def extract_html_content(resource)
    attribute = Accessibility::Issue::HtmlFixer.target_attribute(resource)
    html_content = resource.send(attribute)

    raise InvalidParameterError if html_content.blank?

    html_content
  end

  def extract_and_validate_attachment_id!(element)
    attachment_id = self.class.extract_attachment_id_from_element(element)
    return attachment_id if attachment_id.present?

    raise InvalidParameterError
  end

  def load_and_validate_attachment(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)

    raise InvalidParameterError unless attachment&.grants_right?(@current_user, :read) &&
                                       attachment.size <= AI_ALT_TEXT_MAX_IMAGE_SIZE &&
                                       AI_ALT_TEXT_SUPPORTED_IMAGE_TYPES.include?(attachment.content_type)

    attachment
  end

  def call_cedar_alt_text_generation(attachment)
    base64_source = Base64.strict_encode64(attachment.open.read)

    generation_result = CedarClient.generate_alt_text(
      image: { base64_source:, type: AI_ALT_TEXT_TYPE },
      feature_slug: AI_ALT_TEXT_FEATURE_FLAG_SLUG,
      root_account_uuid: @context.root_account.uuid,
      current_user: @current_user,
      max_length: AI_ALT_TEXT_MAX_LENGTH,
      target_language:
    )

    generation_result.image["altText"]
  end

  def target_language
    infer_locale(
      context: @context,
      user: @current_user,
      root_account: @domain_root_account
    )
  end
end
