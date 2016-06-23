YARD::Templates::Engine.register_template_path Pathname.new(File.dirname(__FILE__))

class RegisterExpansionHandler < YARD::Handlers::Ruby::Base
  handles method_call(:register_expansion)
  namespace_only

  def process
    variable_substitution = statement.parameters.first.jump(:tstring_content, :ident).source
    guard = (
      statement.parameters[3] && statement.parameters[3].jump(:tstring_content, :ident).source.to_s
    ) || 'ALWAYS'

    object = register YARD::CodeObjects::MethodObject.new(namespace, variable_substitution)
    parse_block(statement, :owner => object)

    deprecated_str = ''
    deprecated_str = ' *[deprecated]*' if object.tags(:deprecated).count > 0

    example_tags = object.tags(:example)
    example = example_tags.count > 0 && object.tags(:example).first

    example_text = ''
    example_text = "\n\n#{example.text}" if example

    description = if statement.comments
                    d = statement.comments.match(/([^@]+)@?/m)[1].strip
                    d = "#{d}." unless ['.', '!', '?'].include? d[-1]
                    d = "#{d} "
                    d
                  else
                    ''
                  end
    description = case guard
                  when 'ALWAYS'
                    "#{description}Should always be available."
                  when 'USER_GUARD'
                    "#{description}Only available when launched by a logged in user."
                  when 'USAGE_RIGHTS_GUARD'
                    "#{description}Only available when an attachment is present and has usage rights defined."
                  when 'MEDIA_OBJECT_GUARD'
                    "#{description}Only available when an attachment is present and has a media object defined."
                  when 'PSEUDONYM_GUARD'
                    "#{description}Only available when pseudonym is in use."
                  when 'ENROLLMENT_GUARD'
                    "#{description}Only available when launched from a course."
                  when 'ROLES_GUARD'
                    "#{description}Only available when launched from a course or an account."
                  when 'CONTENT_TAG_GUARD'
                    "#{description}Only available when content tag is present."
                  when 'ASSIGNMENT_GUARD'
                    "#{description}Only available when launched as an assignment."
                  when 'MEDIA_OBJECT_ID_GUARD'
                    "#{description}Only available when an attachment is present and it has either a media object or media entry id defined."
                  when 'LTI1_GUARD'
                    "#{description}Only available for LTI 1."
                  when 'MASQUERADING_GUARD'
                    "#{description}Only available when the user is being masqueraded."
                  when 'COURSE_GUARD'
                    "#{description}Only available when launched in a course."
                  when 'TERM_START_DATE_GUARD'
                    "#{description}Only available when launched in a course that has a term with a start date."
                  else
                    "#{description}"
                  end

    DocWriter.append_md "## #{variable_substitution}#{deprecated_str}\n#{description}#{example_text}\n\n"
  end

  private
  def object
    @object ||= YARD::CodeObjects::ClassVariableObject.new(namespace, "LTI_Substitutions")
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
