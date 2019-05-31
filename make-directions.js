#!/usr/bin/env node
var directions = require('./' + process.argv[2])
var values = require('./' + process.argv[3])

var output = []
directions.forEach(function (direction) {
  var label = direction.label
  var blank = direction.blank
  var value = values[label]
  if (value) output.push({ value, blank })
})
console.log(JSON.stringify(output, null, 2))
process.exit(0)
