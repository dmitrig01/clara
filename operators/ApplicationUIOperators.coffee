_ = require 'underscore'
#FieldTypes = require '../lib/FieldTypes'

module.exports = (models, operators) ->
  '''
csvLine2Array = (line, options) ->
  reValid = /^\s*(?:D[^D\\]*(?:\\[S\s][^D\\]*)*D|[^SD\s\\]*(?:\s+[^SD\s\\]+)*)\s*(?:S\s*(?:D[^D\\]*(?:\\[S\s][^D\\]*)*D|[^SD\s\\]*(?:\s+[^SD\s\\]+)*)\s*)*$/
  reValid = RegExp (reValid.source.replace /S/g, options.separator), "g"
  reValid = RegExp (reValid.source.replace /D/g, options.delimiter), "g"
  return unless reValid.test line # Make sure the line is valid

  if options.delimiter
    reValue = /(?!\s*$)\s*(?:D([^D\\]*(?:\\[S\s][^D\\]*)*)D|([^SD\s\\]*(?:[^SD\\]+)*))\s*(?:S|$)/g
    reValue = RegExp (reValue.source.replace /S/g, options.separator), "g"
    reValue = RegExp (reValue.source.replace /D/g, options.delimiter), "g"
    reDelimiterUnescape = /\\D/g
    reDelimiterUnescape = RegExp reDelimiterUnescape.source.replace(/D/, options.delimiter), "g"

    lineParts = []
    line.replace reValue, (m0, m1, m2) ->
      if m1 isnt `undefined`
        lineParts.push m1.replace reDelimiterUnescape, options.delimiter 
      else if m2 isnt `undefined`
        lineParts.push m2
      ""
    lineParts
  else
    line.split options.separator
'''