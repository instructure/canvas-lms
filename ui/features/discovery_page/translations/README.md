# Discovery Page Translations

Translations for the Identity Service discovery page UI.

## Purpose

The Identity Service renders a discovery page that lets users choose how to
sign in. Rather than maintaining its own translation pipeline, it consumes
translations produced by Canvas's existing i18nliner / Zab workflow.

Strings defined in `discoveryPageTranslations.ts` are extracted by
`i18nliner export`, included in the English source file sent to Zab, and
returned as translated locale files that the Identity Service reads at
runtime.

## Adding new strings

1. Add a new entry to `discoveryPageTranslations.ts` using `I18n.t()`.
2. Merge to master. The daily `canvas_transifreq` job will pick up the new
   string, send it to Zab for translation, and commit the translated locale
   files back into the repo.

## Current strings

| Key                | English text              |
|--------------------|---------------------------|
| `selectLoginMethod`| Select a login method     |
| `moreSignInOptions`| More sign in options      |
