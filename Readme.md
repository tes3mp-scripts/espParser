# espParser

A reworked version of [Jakob's espParser](https://github.com/JakobCh/tes3mp_scripts/tree/master/espParser)
Made for the next tes3mp release, doesn't work with 0.7-alpha

I'm accepting pull requests for the currently unparsed subrecords (look for `p.TODO`)

## Config
* `espPath` path to the esp folder inside `server/data`. Default value: `custom/esps`
* `useRequiredDataFiles` whether espParser should use `requiredDataFiles.json` for the load order. Default value: `true`
* `requiredDataFiles` path to `requiredDataFiles.json` inside data (or another file if you wish). Default value: `requiredDataFiles.json`
* `files` array of files to load if `useRequiredDataFiles` is `false`. Default value: `[]`
* `loadOnStart` whether espParser should go through all the esp files on server start. Default value: `false`

## Events
* `espParser_Start(files)` before any files are parsed
  * `files` list of files to be parsed
* `espParser_File(file)` at the beginning of each esm/esp file
  * `file` name of the current file
* `espParser_Record(record, file)` for each record
  * `record` a table with the given record
  * `file` name of the current file
* `espParser_Finish(files)` after parsing is finished
  * `files` list of files to be parsed

## Server window command
* `espparser` starts the parsing process, same as `loadOnStart` does on server start