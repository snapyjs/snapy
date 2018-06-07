{test} = require "../src/snapy-client.coffee"
test (snap) =>
  # should exit snapy 
  setImmediate => throw new Error "should throw and fail"
  new Promise (resolve,reject) =>
    reject new Error "unhandled reject"
  snap promise: new Promise (resolve) => setTimeout resolve,10 