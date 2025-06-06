# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

YARD::Templates::Engine.register_template_path Pathname.new(File.dirname(__FILE__))

class RegisterExpansionHandler < YARD::Handlers::Ruby::Base
  handles method_call(:register_expansion)
  namespace_only

  def process
    variable_substitution = statement.parameters.first.jump(:tstring_content, :ident).source

    object = register YARD::CodeObjects::MethodObject.new(namespace, variable_substitution)
    return if object.tags(:internal).any?

    parse_block(statement, owner: object)

    deprecated_str = ""
    deprecated_str = " *[deprecated]*" if object.tags(:deprecated).count > 0

    example_tags = object.tags(:example)
    example = example_tags.count > 0 && example_tags.first

    example_text = ""
    example_text = example.text.to_s if example

    # launch_param_tags = object.tags(:launch_parameter)
    # launch_param = launch_param_tags.count > 0 && launch_param_tags.first
    #
    # launch_param_text = ''
    # launch_param_text = "Launch Parameter: *#{launch_param.text}*" if launch_param

    duplicates_tags = object.tags(:duplicates)
    duplicates = duplicates_tags.count > 0 && duplicates_tags.first

    duplicates_text = ""
    duplicates_text = " [duplicates #{duplicates.text}]" if duplicates

    description = if statement.comments
                    d = statement.comments.match(/([^@]+)@?/m)[1].strip
                    d = "#{d}." unless [".", "!", "?"].include? d[-1]
                    d = "#{d} "
                    d
                  else
                    ""
                  end
    DocWriter.append_md <<~MD
      ## #{variable_substitution}#{deprecated_str}#{duplicates_text}
      #{description.strip}

      #{availability}
      #{launch_param_text}

      #{example_text}
    MD
  end

  private

  def launch_param_text
    m = /default_name: '?"?([^'"]+)/.match(statement.parameters[statement.parameters.length - 2].source.to_s)
    "**Launch Parameter**: *#{m[1]}*  " if m
  end

  def all_guards
    guards = []
    (3..8).each do |i|
      param = statement.parameters[i]
      next unless param

      text = param.jump(:tstring_content, :ident).source.to_s
      guards.push(text) if /_GUARD$/.match? text
    end

    guards.push("ALWAYS") if guards.empty?
    guards
  end

  def availability
    all_availabilities = all_guards.filter_map do |guard|
      case guard
      when "ALWAYS", "CONTROLLER_FREE_FF_OR_CONTROLLER_GUARD"
        "always"
      when "CONTROLLER_GUARD"
        "when a tool is launched (excludes background messages like PNS notices)"
      when "USER_GUARD"
        "when launched by a logged in user"
      when "SIS_USER_GUARD"
        "when launched by a logged in user that was added via SIS"
      when "USAGE_RIGHTS_GUARD"
        "when an attachment is present and has usage rights defined"
      when "MEDIA_OBJECT_GUARD"
        "when an attachment is present and has a media object defined"
      when "PSEUDONYM_GUARD"
        "when pseudonym is in use"
      when "ENROLLMENT_GUARD"
        "when launched from a course (or a Group within a course)"
      when "ROLES_GUARD"
        "when launched from a course or an account (or a Group within a course or account)"
      when "CONTENT_TAG_GUARD"
        "when content tag is present"
      when "ASSIGNMENT_GUARD"
        "when launched as an assignment"
      when "MEDIA_OBJECT_ID_GUARD"
        "when an attachment is present and it has either a media object or media entry id defined"
      when "LTI1_GUARD"
        "when in an LTI 1"
      when "MASQUERADING_GUARD"
        "when the user is being masqueraded"
      when "COURSE_GUARD"
        "when launched in a course (or a Group within a course)"
      when "TERM_START_DATE_GUARD"
        "when launched in a course (or a Group within a course) that has a term with a start date"
      when "TERM_END_DATE_GUARD"
        "when launched in a course (or a Group within a course) that has a term with a end date"
      when "TERM_NAME_GUARD"
        "when launched in a course (or a Group within a course) that has a term with a name"
      when "TERM_ID_GUARD"
        "when launched in a course (or a Group within a course) that has a term "
      when "STUDENT_ASSIGNMENT_GUARD"
        "when launched as an assignment by a student"
      when "EDITOR_GUARD"
        "when the tool is launched from the editor_button placement"
      when "FILE_UPLOAD_GUARD"
        "when the tool is used to upload a file as an assignment submission"
      when "INTERNAL_TOOL_GUARD"
        "internal LTI tools"
      when "INSTRUCTURE_IDENTITY_GUARD"
        "Instructure Identity is enabled"
      end
    end
    "**Availability**: *#{all_availabilities.join(" and ")}*  " if all_availabilities.size
  end
end

module DocWriter
  def self.append_md(md)
    markdown_file
    File.write("doc/api/tools_variable_substitutions.md", md, File.size("doc/api/tools_variable_substitutions.md"), mode: "a")
  end

  def self.markdown_file
    @markdown_file ||= begin
      IO.copy_stream("doc/api/tools_variable_substitutions.head.md", "doc/api/tools_variable_substitutions.md")
      true
    end
  end
end
