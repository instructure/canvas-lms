require "jsduck/tag/tag"

class Seed < JsDuck::Tag::Tag
  def initialize
    @tagname = :seed
    @pattern = "seed"
    @repeatable = true
    @html_position = POS_DOC + 0.1
  end

  def parse_doc(scanner, position)
    name = scanner.match(/.*$/) || scanner.ident
    name = 'A generic example' if name.empty?
    return { tagname: :seed, name: name, doc: :multiline }
  end

  def process_doc(context, tags, position)
    context[:seed] = tags
  end

  def to_html(context, *args)
    seeds = context[:seed].map do |seed|
      <<-HTML
        <dt class='seed-name'><a>#{seed[:name]}</a></dt>
        <dd>
          <pre class='seed-data'>#{seed[:doc]}</pre>
          <div class='seed-runner'></div>
        </dd>
      HTML
    end.join("\n")

    <<-HTML
      <h3 class="pa">Live Examples</h3>
      <dl>
        #{seeds}
      </dl>
    HTML
  end
end