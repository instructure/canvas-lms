if CANVAS_RAILS2
  # vanilla RailsXss uses safe_concat in a broken way. patch it up to use append=
  # instead (matches rails3 behavior).
  module RailsXss
    class Erubis < ::Erubis::Eruby
      def add_expr_literal(src, code)
        if code =~ BLOCK_EXPR
          src << "@output_buffer.append= " << code
        else
          src << '@output_buffer << ((' << code << ').to_s);'
        end
      end
    end
  end
end
