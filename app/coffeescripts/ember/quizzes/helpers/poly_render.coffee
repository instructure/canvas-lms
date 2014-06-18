define ['ember'], (Ember) ->
  # A version of {{render}} that supports dynamic view types/paths based on
  # a model's attribute. Useful for polymorphic models which may need to be
  # represented by different controllers and views based on their type.
  #
  # @param {String} path
  #   Path to the model property that will be used to identify the template to
  #   render.
  #
  # @param {DS.Model or Object} model
  #   The model you're rendering. It will be passed to the custom controller and
  #   must have the attribute you specified in @path present.
  #
  # @param {Object} options
  # @param {String} options.prefix
  #   A slash-delimited to prefix the template path (resolved from @path) with.
  #   It's highly likely you will need to specify this unless your templates
  #   are in the root folder, or the @path attribute on the model already
  #   contains the full-path to the template.
  #
  # ===
  # Example usage
  #
  # Say we have a QuizQuestion model that has a "type"
  # property which may be any of 'multiple_choice', 'true_false', or other
  # values, and we need to render some of these types using custom controllers
  # and views.
  #
  # Here's our basic model:
  #
  # ```javascript
  #   QuizQuestion = DS.Model.extend({
  #     questionType: DS.attr('string')
  #   });
  # ```
  #
  # And here's how we can render each question in the set:
  #
  # ```handlebars
  # {{#each question in quizQuestions}}
  #   {{polyRender question.questionType question prefix="quiz/questions/"}}
  # {{/each}}
  # ```
  #
  # If one of our questions had a questionType of "multiple_choice", the call
  # to #polyRender will:
  #
  #   - look for a template at "quiz/questions/multiple_choice.hbs"
  #   - look for a controller named QuizQuestionsMultipleChoiceController
  #   - look for a view named QuizQuestionsMultipleChoiceView
  #
  # ===
  # See the resources related to QuestionStatistics for more usage examples.
  Ember.Handlebars.helper 'polyRender', (path, model, options) ->
    params = []
    hasModel = arguments.length == 3

    unless hasModel
      options = model

    prefix = options.hash.prefix || ''
    params.push( prefix + path )

    # a hack to avoid the "using quoteless parameter" warning...
    options.types[0] = '';

    if hasModel
      options.contexts[1] = { model: model }
      params.push('model')

    params.push(options)

    Ember.Handlebars.helpers.render.apply(this, params)