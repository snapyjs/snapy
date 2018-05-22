{test} = require "../src/snapy-client.coffee"
test (snap) =>
  ###
    some block comment
  ###
  # some comment
  snap obj: 
    static: 
      obj: 
        remaining: 
          unchanged: true
    sibling: true