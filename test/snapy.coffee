{test} = require "../src/snapy-client.coffee"
test (snap) =>
  ###
    some block commen
  ###
  # some comment
  snap obj: 
    static: 
      obj: 
        remaining: 
          unchanged: true
    sibling: true