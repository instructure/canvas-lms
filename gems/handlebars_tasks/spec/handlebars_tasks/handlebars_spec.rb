require 'spec_helper'

module HandlebarsTasks
  describe Handlebars do
    describe "#compile_template" do
      context "with basic template" do
        let(:template) do
          <<-HTML
            <h1>{{title}}</h1>
            <p>{{#t "message"}}ohai my name is {{name}} im your <b>{{type}}</b> instructure!! ;) heres some tips to get you started:{{/t}}</p>
            <ol>
              {{#each items}}
              <li>{{#t "protip" type=../type}}Important {{type}} tip:{{/t}} {{this}}</li>
              {{/each}}
            </ol>
            <p>{{#t "html"}}lemme instructure you some html: if you type {{input}}, you get {{{input}}}{{/t}}</p>
            <p>{{#t "reversed"}}in other words you get {{{input}}} when you type {{input}}{{/t}}</p>
            <p>{{#t "escapage"}}this is {{escaped}}{{/t}}</p>
            <p>{{#t "unescapage"}}this is {{{unescaped}}}{{/t}}</p>
            {{#t "bye"}}welp, see you l8r! dont forget 2 <a href="{{url}}">like us</a> on facebook lol{{/t}}
          HTML
        end

        let(:result){ HandlebarsTasks::Handlebars.compile_template(template, 'test', 'test') }

        it "includes appropriate translations" do
          expect(result).to match(/define\(.*i18n\!test/)
        end

        it "injects the handlebars_helpers dependency" do
          expect(result).to match(
            %r{define\(.*\["compiled\/handlebars_helpers".*function \(Handlebars\) \{}
          )
        end

        it "invokes translation helpr for translatable blocks" do
          expect(result).to match(
            %r{\.call\([^,]*, "message", "ohai my name is %\{name\} im your \*%\{type\}\* instructure!! ;\) heres some tips to get you started:", options\)}
          )
        end
      end

      context "with partials" do
        let!(:partial) do
          HandlebarsTasks::Handlebars.compile_template("hi from inside partial",
                                                       "_test_partial",
                                                       '_test_partial')
        end

        let(:result) do
          HandlebarsTasks::Handlebars.compile_template("outside partial {{>test_partial}}", "test_template", 'test_template')
        end

        it "requires partials used within templates" do
          expect(result).to match(
            %r{define\(.*"jst/_test_partial"}
          )
        end

        it "replaces the partial invocation" do
          expect(result).to match(
            %r{self.invokePartial\(partials.test_partial, 'test_partial'}
          )
        end
      end
    end
  end
end
