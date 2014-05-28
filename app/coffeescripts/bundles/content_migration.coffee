require [
  'i18n!content_migrations'
  'jquery'
  'compiled/collections/ProgressingContentMigrationCollection'
  'compiled/models/ContentMigration'
  'compiled/collections/DaySubstitutionCollection'
  'compiled/views/CollectionView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/content_migrations/ProgressingContentMigrationView'
  'compiled/views/content_migrations/MigrationConverterView'
  'compiled/views/content_migrations/CommonCartridgeView'
  'compiled/views/content_migrations/ConverterViewControl'
  'compiled/views/content_migrations/ZipFilesView'
  'compiled/views/content_migrations/CopyCourseView'
  'compiled/views/content_migrations/MoodleZipView'
  'compiled/views/content_migrations/CanvasExportView'
  'compiled/views/content_migrations/QTIZipView'
  'compiled/views/content_migrations/subviews/ChooseMigrationFileView'
  'compiled/views/content_migrations/subviews/FolderPickerView'
  'compiled/views/content_migrations/subviews/SelectContentCheckboxView'
  'compiled/views/content_migrations/subviews/QuestionBankView'
  'compiled/views/content_migrations/subviews/CourseFindSelectView'
  'compiled/views/content_migrations/subviews/DateShiftView'
  'compiled/views/content_migrations/subviews/DaySubstitutionView'
  'jst/content_migrations/ProgressingContentMigrationCollection'
  'compiled/views/content_migrations/ExternalToolContentView'
  'compiled/views/content_migrations/subviews/ExternalToolLaunchView'
  'compiled/views/ExternalTools/ExternalContentReturnView'
  'compiled/models/ExternalTool'
  'vendor/jquery.ba-tinypubsub'
  'jst/content_migrations/subviews/DaySubstitutionCollection'
  'compiled/views/content_migrations/subviews/OverwriteAssessmentContentView'
], (I18n, $,
    ProgressingContentMigrationCollection,
    ContentMigrationModel,
    DaySubstitutionCollection,
    CollectionView,
    PaginatedCollectionView,
    ProgressingContentMigrationView,
    MigrationConverterView,
    CommonCartridgeView,
    ConverterViewControl,
    ZipFilesView,
    CopyCourseView,
    MoodleZipView,
    CanvasExportView,
    QTIZipView,
    ChooseMigrationFileView,
    FolderPickerView,
    SelectContentCheckboxView,
    QuestionBankView,
    CourseFindSelectView,
    DateShiftView,
    DaySubView,
    progressingMigrationCollectionTemplate,
    ExternalToolContentView,
    ExternalToolLaunchView,
    ExternalContentReturnView,
    ExternalTool,
    pubsub,
    daySubCollectionTemplate,
    OverwriteAssessmentContentView) ->
  ConverterViewControl.setModel new ContentMigrationModel
                                 course_id: ENV.COURSE_ID
                                 daySubCollection: daySubCollection
  
  daySubCollection          = new DaySubstitutionCollection
  daySubCollectionView      = new CollectionView
                                 collection: daySubCollection
                                 emptyMessage: -> I18n.t('no_day_substitutions', "No Day Substitutions Added")
                                 itemView: DaySubView
                                 template: daySubCollectionTemplate

  progressingMigCollection  = new ProgressingContentMigrationCollection null,
                                 course_id: ENV.COURSE_ID

  progressingCollectionView = new PaginatedCollectionView
                                 el: '#progress'
                                 collection: progressingMigCollection
                                 template: progressingMigrationCollectionTemplate
                                 emptyMessage: -> I18n.t('no_migrations_running', "There are no migrations currently running")
                                 itemView: ProgressingContentMigrationView

  progressingCollectionView.getStatusView = (migProgress) ->
    if getView = ConverterViewControl.getView(migProgress.get('migration_type'))?.view?.getStatusView
      getView(migProgress)

  progressingCollectionView.render()

  migrationConverterView    = new MigrationConverterView
                                 el: '#migrationConverterContainer'
                                 selectOptions: ENV.SELECT_OPTIONS
                                 model: ConverterViewControl.getModel()
  migrationConverterView.render()

  dfd = progressingMigCollection.fetch()
  progressingCollectionView.$el.disableWhileLoading dfd

  # Migration has now started and is being processed at this point. 
  $.subscribe 'migrationCreated', (migrationModelData) -> 
    progressingMigCollection.add migrationModelData

  # Registers any subviews with any changes that happen 
  # when selecting a converter. Give it the value to
  # look for then the subview to insert. Works like 
  # this 
  #
  # ie   ConverterChange.register key: 'some_dropdown_value', view: new BackboneView

  ConverterViewControl.register
    key: 'zip_file_importer'
    view: new ZipFilesView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            folderPicker:        new FolderPickerView 
                                   model: ConverterViewControl.getModel()
                                   folderOptions: ENV.FOLDER_OPTIONS

  ConverterViewControl.register 
    key: 'course_copy_importer'
    view: new CopyCourseView
            courseFindSelect: new CourseFindSelectView 
                                current_user_id: ENV.current_user_id
                                model: ConverterViewControl.getModel()

            selectContent:    new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE


  ConverterViewControl.register
    key: 'moodle_converter'
    view: new MoodleZipView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            questionBank:        new QuestionBankView
                                   model: ConverterViewControl.getModel()
                                   questionBanks: ENV.QUESTION_BANKS

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

  ConverterViewControl.register
    key: 'canvas_cartridge_importer'
    view: new CanvasExportView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

  ConverterViewControl.register
    key: 'common_cartridge_importer'
    view: new CommonCartridgeView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())
            overwriteAssessmentContent: new OverwriteAssessmentContentView(model: ConverterViewControl.getModel())

            questionBank:        new QuestionBankView
                                   questionBanks: ENV.QUESTION_BANKS
                                   model: ConverterViewControl.getModel()

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

  ConverterViewControl.register
    key: 'qti_converter'
    view: new QTIZipView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            overwriteAssessmentContent: new OverwriteAssessmentContentView(model: ConverterViewControl.getModel())
            questionBank:        new QuestionBankView(questionBanks: ENV.QUESTION_BANKS)


  registerExternalTool = (et) ->
    toolModel = new ExternalTool(et)
    returnView = new ExternalContentReturnView
      model: toolModel
      launchType: 'migration_selection'

    launchView = new ExternalToolLaunchView
      model: ConverterViewControl.getModel()
      contentReturnView: returnView

    selectContentView = new SelectContentCheckboxView
      model: ConverterViewControl.getModel()

    contentView = new ExternalToolContentView
      selectContent: selectContentView
      externalToolLaunch: launchView

    ConverterViewControl.register
      key: toolModel.assetString()
      view: contentView

  for et in ENV.EXTERNAL_TOOLS
    registerExternalTool(et)
