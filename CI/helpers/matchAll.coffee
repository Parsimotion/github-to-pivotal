_ = require "lodash"

matchOne = (regex, string) ->
  match = regex.exec string
  _.nth match, 1

module.exports = (regex, string) =>
  matches = [];
  match = matchOne regex, string
  while (match)
    matches.push(match)
    match = matchOne regex, string
  
  matches