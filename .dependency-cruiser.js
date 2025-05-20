/** @type {import('dependency-cruiser').IConfiguration} */

module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      comment:
        'This dependency is part of a circular relationship. You might want to revise ' +
        'your solution (i.e. use dependency inversion, make sure the modules have a single responsibility) ',
      from: {
        pathNot: [
          // TODO: remove these
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/components/ExternalToolDialog/ExternalToolDialog.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/dialog-helper.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/ExternalToolsEnv.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti11-content-items/RceLti11ContentItem.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti13-content-items/models/ResourceLinkContentItem.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti13-content-items/processEditorContentItems.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti13-content-items/rceLti13ContentItemFromJson.js',
          'packages/canvas-rce/es/rce/plugins/instructure_rce_external_tools/RceToolWrapper.js',
          'packages/canvas-rce/es/rce/RCEWrapper.js',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/components/ExternalToolDialog/ExternalToolDialog.tsx',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/components/ExternalToolSelectionDialog/ExternalToolSelectionDialog.tsx',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/dialog-helper.tsx',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/ExternalToolsEnv.ts',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/lti11-content-items/RceLti11ContentItem.tsx',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/lti13-content-items/models/ResourceLinkContentItem.ts',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/lti13-content-items/processEditorContentItems.ts',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/lti13-content-items/rceLti13ContentItemFromJson.ts',
          'packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/RceToolWrapper.ts',
          'packages/canvas-rce/src/rce/RCEWrapper.jsx',
          'ui/features/course_paces/react/actions/course_paces.ts',
          'ui/features/course_paces/react/actions/pace_contexts.ts',
          'ui/features/course_paces/react/actions/ui.ts',
          'ui/features/course_paces/react/api/blackout_dates_api.ts',
          'ui/features/course_paces/react/reducers/course_paces.ts',
          'ui/features/course_paces/react/reducers/original.ts',
          'ui/features/course_paces/react/shared/actions/blackout_dates.ts',
          'ui/features/course_paces/react/shared/reducers/blackout_dates.ts',
          'ui/features/enhanced_individual_gradebook/react/components/GradingResults/CheckpointGradeInputs.tsx',
          'ui/features/enhanced_individual_gradebook/react/components/GradingResults/DefaultGradeInput.tsx',
          'ui/features/enhanced_individual_gradebook/react/components/GradingResults/index.tsx',
          'ui/features/enhanced_individual_gradebook/react/components/GradingResults/SubmissionDetailModal.tsx',
          'ui/features/enhanced_individual_gradebook/react/components/LearningMasteryTabsView.tsx',
          'ui/features/enhanced_individual_gradebook/react/components/OutcomeInformation/index.tsx',
          'ui/features/enhanced_individual_gradebook/react/hooks/useSubmitScore.tsx',
          'ui/features/enhanced_individual_gradebook/utils/gradebookUtils.ts',
          'ui/features/enhanced_individual_gradebook/utils/gradeInputUtils.ts',
          'ui/features/gradebook/react/default_gradebook/components/GradebookGrid.tsx',
          'ui/features/gradebook/react/default_gradebook/components/InputsForCheckpoints.tsx',
          'ui/features/gradebook/react/default_gradebook/components/SubmissionTray.tsx',
          'ui/features/gradebook/react/default_gradebook/Gradebook.tsx',
          'ui/features/gradebook/react/default_gradebook/GradebookGrid/formatters/AssignmentGroupCellFormatter.ts',
          'ui/features/gradebook/react/default_gradebook/GradebookGrid/formatters/CellFormatterFactory.ts',
          'ui/features/lti_registrations/manage/lti_1p3_registration_form/Lti1p3RegistrationOverlayState.ts',
          'ui/features/lti_registrations/manage/lti_1p3_registration_form/Lti1p3RegistrationOverlayStateHelpers.ts',
          'ui/features/speed_grader/react/SpeedGraderCheckpoints/SpeedGraderCheckpoint.tsx',
          'ui/features/speed_grader/react/SpeedGraderCheckpoints/SpeedGraderCheckpointsContainer.tsx',
          'ui/shared/assignments/react/AssignmentHeader.tsx',
          'ui/shared/assignments/react/OptionsMenu.tsx',
          'ui/shared/block-editor/react/assets/globalTemplates/index.ts',
          'ui/shared/block-editor/react/components/user/blocks/IconBlock/IconBlock.tsx',
          'ui/shared/block-editor/react/components/user/blocks/IconBlock/IconBlockToolbar.tsx',
          'ui/shared/block-editor/react/components/user/blocks/IconBlock/index.ts',
          'ui/shared/block-editor/react/components/user/common/IconPopup.tsx',
          'ui/shared/block-editor/react/utils/getTemplates.tsx',
          'ui/shared/block-editor/react/utils/index.ts',
          'ui/shared/context-modules/differentiated-modules/react/Item/ItemAssignToTray.tsx',
          'ui/shared/context-modules/differentiated-modules/react/Item/ItemAssignToTrayContent.tsx',
          'ui/shared/context-modules/react/ContextModulesPublishIcon.tsx',
          'ui/shared/context-modules/utils/publishOneModuleHelper.tsx',
          'ui/shared/files/backbone/models/Folder.js',
          'ui/shared/files/react/modules/filesEnv.js',
          'ui/shared/lti/jquery/messages.ts',
          'ui/shared/lti/jquery/subjects/lti.resourceImported.ts',
          'ui/shared/lti/jquery/subjects/requestFullWindowLaunch.ts',
          'ui/shared/mediaelement/index.js',
          'ui/shared/mediaelement/mep-feature-tracks-instructure.jsx',
          'ui/shared/mediaelement/UploadMediaTrackForm.jsx',
          'ui/shared/temporary-enrollment/react/EnrollmentTreeGroup.tsx',
          'ui/shared/temporary-enrollment/react/EnrollmentTreeItem.tsx',
        ],
      },
      to: {
        circular: true,
      },
    },
    {
      name: 'no-orphans',
      comment:
        "This is an orphan module - it's likely not used (anymore?). Either use it or " +
        "remove it. If it's logical this module is an orphan (i.e. it's a config file), " +
        'add an exception for it in your dependency-cruiser configuration. By default ' +
        'this rule does not scrutinize dot-files (e.g. .eslintrc.js), TypeScript declaration ' +
        'files (.d.ts), tsconfig.json and some of the babel and webpack configs.',
      severity: 'warn',
      from: {
        orphan: true,
        pathNot: [
          '(^|/)[.][^/]+[.](?:js|cjs|mjs|ts|cts|mts|json)$', // dot files
          '[.]d[.]ts$', // TypeScript declaration files
          '(^|/)tsconfig[.]json$', // TypeScript config
          '(^|/)(?:babel|webpack|jest|vitest|eslint)[.]config[.](?:js|cjs|mjs|ts|cts|mts|json)$',
        ],
      },
      to: {},
    },
    {
      name: 'no-deprecated-core',
      comment:
        'A module depends on a node core module that has been deprecated. Find an alternative - these are ' +
        "bound to exist - node doesn't deprecate lightly.",
      severity: 'warn',
      from: {},
      to: {
        dependencyTypes: ['core'],
        path: [
          '^v8/tools/codemap$',
          '^v8/tools/consarray$',
          '^v8/tools/csvparser$',
          '^v8/tools/logreader$',
          '^v8/tools/profile_view$',
          '^v8/tools/profile$',
          '^v8/tools/SourceMap$',
          '^v8/tools/splaytree$',
          '^v8/tools/tickprocessor-driver$',
          '^v8/tools/tickprocessor$',
          '^node-inspect/lib/_inspect$',
          '^node-inspect/lib/internal/inspect_client$',
          '^node-inspect/lib/internal/inspect_repl$',
          '^async_hooks$',
          '^punycode$',
          '^domain$',
          '^constants$',
          '^sys$',
          '^_linklist$',
          '^_stream_wrap$',
        ],
      },
    },
    {
      name: 'not-to-deprecated',
      comment:
        'This module uses a (version of an) npm module that has been deprecated. Either upgrade to a later ' +
        'version of that module, or find an alternative. Deprecated modules are a security risk.',
      severity: 'warn',
      from: {},
      to: {
        dependencyTypes: ['deprecated'],
      },
    },
    {
      name: 'no-non-package-json',
      severity: 'error',
      comment:
        "This module depends on an npm package that isn't in the 'dependencies' section of your package.json. " +
        "That's problematic as the package either (1) won't be available on live (2 - worse) will be " +
        'available on live with an non-guaranteed version. Fix it by adding the package to the dependencies ' +
        'in your package.json.',
      from: {},
      to: {
        dependencyTypes: ['npm-no-pkg', 'npm-unknown'],
      },
    },
    {
      name: 'not-to-unresolvable',
      comment:
        "This module depends on a module that cannot be found ('resolved to disk'). If it's an npm " +
        'module: add it to your package.json. In all other cases you likely already know what to do.',
      severity: 'error',
      from: {
        pathNot: ['ui/shared/datetime/__tests__/momentSpec.js'],
      },
      to: {
        couldNotResolve: true,
      },
    },
    {
      name: 'no-duplicate-dep-types',
      comment:
        "Likely this module depends on an external ('npm') package that occurs more than once " +
        'in your package.json i.e. bot as a devDependencies and in dependencies. This will cause ' +
        'maintenance problems later on.',
      severity: 'warn',
      from: {},
      to: {
        moreThanOneDependencyType: true,
        // as it's pretty common to have a type import be a type only import
        // _and_ (e.g.) a devDependency - don't consider type-only dependency
        // types for this rule
        dependencyTypesNot: ['type-only'],
      },
    },

    {
      name: 'not-to-spec',
      comment:
        'This module depends on a spec (test) file. The sole responsibility of a spec file is to test code. ' +
        "If there's something in a spec that's of use to other modules, it doesn't have that single " +
        'responsibility anymore. Factor it out into (e.g.) a separate utility/ helper or a mock.',
      severity: 'error',
      from: {},
      to: {
        path: '[.](?:spec|test)[.](?:js|mjs|cjs|jsx|ts|mts|cts|tsx[.]md)$',
      },
    },
    {
      name: 'not-to-dev-dep',
      severity: 'error',
      comment:
        "This module depends on an npm package from the 'devDependencies' section of your " +
        'package.json. It looks like something that ships to production, though. To prevent problems ' +
        "with npm packages that aren't there on production declare it (only!) in the 'dependencies'" +
        'section of your package.json. If this module is development only - add it to the ' +
        'from.pathNot re of the not-to-dev-dep rule in the dependency-cruiser configuration',
      from: {
        path: '^(packages)',
        pathNot:
          '[.](?:|config|spec|setup|test|jest-setup)[.](?:js|mjs|cjs|jsx|ts|mts|cts|tsx[.]md)$',
      },
      to: {
        dependencyTypes: ['npm-dev'],
        // type only dependencies are not a problem as they don't end up in the
        // production code or are ignored by the runtime.
        dependencyTypesNot: ['type-only'],
        pathNot: [
          'node_modules/@types/',
          'node_modules/sinon/',
          'node_modules/@testing-library/jest-dom/',
        ],
      },
    },
    {
      name: 'optional-deps-used',
      severity: 'info',
      comment:
        'This module depends on an npm package that is declared as an optional dependency ' +
        "in your package.json. As this makes sense in limited situations only, it's flagged here. " +
        "If you're using an optional dependency here by design - add an exception to your" +
        'dependency-cruiser configuration.',
      from: {},
      to: {
        dependencyTypes: ['npm-optional'],
      },
    },
    {
      name: 'peer-deps-used',
      comment:
        'This module depends on an npm package that is declared as a peer dependency ' +
        'in your package.json. This makes sense if your package is e.g. a plugin, but in ' +
        'other cases - maybe not so much. If the use of a peer dependency is intentional ' +
        'add an exception to your dependency-cruiser configuration.',
      severity: 'warn',
      from: {},
      to: {
        dependencyTypes: ['npm-peer'],
      },
    },
    {
      name: 'no-ui-shared-to-ui-features',
      comment: 'Do not allow imports in ui/shared from ui/features',
      severity: 'error',
      from: {
        path: '^ui/shared',
        pathNot: [
          // TODO: remove these
          'ui/shared/proxy-submission/react/ProxyUploadModal.tsx',
          'ui/shared/global/env/EnvCoursePaces.d.ts',
          'ui/shared/global/env/EnvCourse.d.ts',
        ],
      },
      to: {
        path: '^ui/features',
      },
    },
    {
      name: 'no-packages-to-ui',
      comment: 'Do not allow imports in packages/ from ui/',
      severity: 'error',
      from: {
        path: '^packages/',
        pathNot: ['packages/slickgrid/slick.grid.js'],
      },
      to: {
        path: '^ui/',
      },
    },
    {
      name: 'no-feature-interdependence',
      comment: 'One feature should not depend on another feature (in a separate folder)',
      severity: 'error',
      from: {path: '(^ui/features/)([^/]+)/'},
      to: {path: '^$1', pathNot: '$1$2'},
    },
  ],
  options: {
    skipAnalysisNotInRules: true,
    doNotFollow: {
      path: [
        'node_modules',
        // when we no longer import from /es/ build dirs
        // '/es/'
      ],
    },

    includeOnly: ['ui', 'packages'],

    exclude: ['ui/shared/datetime/__tests__/momentSpec.js'],

    /* false (the default): ignore dependencies that only exist before typescript-to-javascript compilation
       true: also detect dependencies that only exist before typescript-to-javascript compilation
       "specify": for each dependency identify whether it only exists before compilation or also after
     */
    tsPreCompilationDeps: false,

    /* if true combines the package.jsons found from the module up to the base
       folder the cruise is initiated from. Useful for how (some) mono-repos
       manage dependencies & dependency definitions.
     */
    combinedDependencies: false,

    /* TypeScript project file ('tsconfig.json') to use for
       (1) compilation and
       (2) resolution (e.g. with the paths property)

       The (optional) fileName attribute specifies which file to take (relative to
       dependency-cruiser's current working directory). When not provided
       defaults to './tsconfig.json'.
     */
    tsConfig: {
      fileName: 'tsconfig.json',
    },
    enhancedResolveOptions: {
      /* What to consider as an 'exports' field in package.jsons */
      exportsFields: ['exports'],
      /* List of conditions to check for in the exports field.
         Only works when the 'exportsFields' array is non-empty.
      */
      conditionNames: ['import', 'require', 'node', 'default', 'types'],
      /*
         The extensions, by default are the same as the ones dependency-cruiser
         can access (run `npx depcruise --info` to see which ones that are in
         _your_ environment. If that list is larger than you need you can pass
         the extensions you actually use (e.g. [".js", ".jsx"]). This can speed
         up the most expensive step in dependency cruising (module resolution)
          quite a bit.
       */
      extensions: ['.js', '.jsx', '.ts', '.tsx', '.d.ts'],

      /* What to consider a 'main' field in package.json */
      // if you migrate to ESM (or are in an ESM environment already) you will want to
      // have "module" in the list of mainFields, like so:
      // mainFields: ["module", "main", "types", "typings"],
      mainFields: ['main', 'types', 'typings'],
    },
    reporterOptions: {
      dot: {
        collapsePattern: 'node_modules/(?:@[^/]+/[^/]+|[^/]+)',
      },
      archi: {
        collapsePattern:
          '^(?:packages|src|lib(s?)|app(s?)|bin|test(s?)|spec(s?))/[^/]+|node_modules/(?:@[^/]+/[^/]+|[^/]+)',
      },
      text: {
        highlightFocused: true,
      },
    },
  },
}
