require 'test_helper'

class ActiveRecordHelperTest < ActionView::TestCase
  silence_warnings do
    Post = Struct.new("Post", :title, :author_name, :body, :secret, :written_on)
    Post.class_eval do
      alias_method :title_before_type_cast, :title unless respond_to?(:title_before_type_cast)
      alias_method :body_before_type_cast, :body unless respond_to?(:body_before_type_cast)
      alias_method :author_name_before_type_cast, :author_name unless respond_to?(:author_name_before_type_cast)
    end
  end

  def setup_post
    @post = Post.new
    def @post.errors
      Class.new {
        def on(field)
          case field.to_s
          when "author_name"
            "can't be empty"
          when "body"
            true
          else
            false
          end
        end
        def empty?() false end
        def count() 1 end
        def full_messages() [ "Author name can't be empty" ] end
      }.new
    end

    def @post.new_record?() true end
    def @post.to_param() nil end

    def @post.column_for_attribute(attr_name)
      Post.content_columns.select { |column| column.name == attr_name }.first
    end

    silence_warnings do
      def Post.content_columns() [ Column.new(:string, "title", "Title"), Column.new(:text, "body", "Body") ] end
    end

    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret = 1
    @post.written_on  = Date.new(2004, 6, 15)
  end

  def setup
    setup_post

    @response = ActionController::TestResponse.new

    @controller = Object.new
    def @controller.url_for(options)
      options = options.symbolize_keys

      [options[:action], options[:id].to_param].compact.join('/')
    end
  end

  def test_text_field_with_errors_is_safe
    assert text_field("post", "author_name").html_safe?
  end

  def test_text_field_with_errors
    assert_dom_equal(
      %(<div class="fieldWithErrors"><input id="post_author_name" name="post[author_name]" size="30" type="text" value="" /></div>),
      text_field("post", "author_name")
    )
  end
end
