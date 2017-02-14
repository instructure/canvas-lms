YARD::Templates::Engine.register_template_path Pathname.new(File.dirname(__FILE__))

class RegisterExpansionHandler < YARD::Handlers::Ruby::Base
  handles method_call(:register_expansion)
  namespace_only

  def process
    variable_substitution = statement.parameters.first.jump(:tstring_content, :ident).source

    object = register YARD::CodeObjects::MethodObject.new(namespace, variable_substitution)
    parse_block(statement, :owner => object)

    deprecated_str = ''
    deprecated_str = ' *[deprecated]*' if object.tags(:deprecated).count > 0

    example_tags = object.tags(:example)
    example = example_tags.count > 0 && example_tags.first

    example_text = ''
    example_text = "#{example.text}" if example

    # launch_param_tags = object.tags(:launch_parameter)
    # launch_param = launch_param_tags.count > 0 && launch_param_tags.first
    #
    # launch_param_text = ''
    # launch_param_text = "Launch Parameter: *#{launch_param.text}*" if launch_param

    duplicates_tags = object.tags(:duplicates)
    duplicates = duplicates_tags.count > 0 && duplicates_tags.first

    duplicates_text = ''
    duplicates_text = " [duplicates #{duplicates.text}]" if duplicates

    description = if statement.comments
                    d = statement.comments.match(/([^@]+)@?/m)[1].strip
                    d = "#{d}." unless ['.', '!', '?'].include? d[-1]
                    d = "#{d} "
                    d
                  else
                    ''
                  end
    DocWriter.append_md <<~HEREDOC
      ## #{variable_substitution}#{deprecated_str}#{duplicates_text}
      #{description.strip}

      #{availability}
      #{launch_param_text}

      #{example_text}
    HEREDOC
  end

  private

  def launch_param_text
    m = /default_name: '?"?([^'"]+)/.match(statement.parameters[statement.parameters.length - 2].source.to_s)
    return "**Launch Parameter**: *#{m[1]}*  " if m
  end

  def all_guards
    guards = []
    for i in 3..8
      param = statement.parameters[i]
      next unless param
      text = param.jump(:tstring_content, :ident).source.to_s
      guards.push(text) if /_GUARD$/.match text
    end

    guards.push('ALWAYS') if guards.size == 0
    guards
  end

  def availability
    all_availabilities = all_guards.map do |guard|
      case guard
      when 'ALWAYS', 'CONTROLLER_GUARD'
        "always"
      when 'USER_GUARD'
        "when launched by a logged in user"
      when 'SIS_USER_GUARD'
        "when launched by a logged in user that was added via SIS"
      when 'USAGE_RIGHTS_GUARD'
        "when an attachment is present and has usage rights defined"
      when 'MEDIA_OBJECT_GUARD'
        "when an attachment is present and has a media object defined"
      when 'PSEUDONYM_GUARD'
        "when pseudonym is in use"
      when 'ENROLLMENT_GUARD'
        "when launched from a course"
      when 'ROLES_GUARD'
        "when launched from a course or an account"
      when 'CONTENT_TAG_GUARD'
        "when content tag is present"
      when 'ASSIGNMENT_GUARD'
        "when launched as an assignment"
      when 'MEDIA_OBJECT_ID_GUARD'
        "when an attachment is present and it has either a media object or media entry id defined"
      when 'LTI1_GUARD'
        "when in an LTI 1"
      when 'MASQUERADING_GUARD'
        "when the user is being masqueraded"
      when 'COURSE_GUARD'
        "when launched in a course"
      when 'TERM_START_DATE_GUARD'
        "when launched in a course that has a term with a start date"
      end
    end.compact
    "**Availability**: *#{all_availabilities.join(' and ')}*  " if all_availabilities.size
  end
end

module DocWriter

  def self.append_md(md)
    markdown_file
    File.write('doc/api/tools_variable_substitutions.md', md, File.size('doc/api/tools_variable_substitutions.md'), mode: 'a')
  end

  def self.markdown_file
    @markdown_file ||= (
      IO.copy_stream('doc/api/tools_variable_substitutions.head.md', 'doc/api/tools_variable_substitutions.md')
      true
    )
  end

end
