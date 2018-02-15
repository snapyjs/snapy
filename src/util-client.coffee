isArray = Array.isArray
isFunction = (obj) -> typeof obj == "function"
isString = (obj) -> typeof obj == "string" or obj instanceof String
concat = (arr1,arr2) -> Array::push.apply(arr1, arr2); return arr1

splittedToObjects = (splitted, obj) ->
  return splitted.reduce ((arr, name, i) ->
    throw new Error splitted.join(".") + " not a valid path" unless (tmp = arr[i])?
    arr.push tmp[name]
    return arr
    ), [obj]

pathToNameAndParent = (o) ->
  return o if o.name and o.parent
  splitted = o.path.split(".")
  o.name = splitted.pop()
  o.parent = splittedToObjects(splitted, o.obj).pop()
  return o

pathToValue = (o) ->
  {parent, name} = pathToNameAndParent(o)
  return parent[name]

normalizeMapping = (name,{state}) ->
  if (tmp = state[name])?
    if isString(tmp)
      tmp = [tmp]
    if isArray(tmp)
      tmp2 = {}
      for str in tmp
        tmp2[str] = str
      state[name] = tmp2

processMapping = (name, fn, {state},{Promise}) ->
  if (mapping = state[name])?
    delete state[name]
    if (obj = state.obj)?
      workers = []
      for k,v of mapping
        if v
          {parent,name} = pathToNameAndParent(obj:obj, path: v)
        else
          parent = state
          name = "obj"
        if k
          value = pathToValue(obj:obj, path:k)
        else
          value = obj
        workers.push fn(parent, name, value, state)
      return Promise.all(workers)
    else
      return fn(state,"obj",mapping, state)

module.exports =
  pathToNameAndParent: pathToNameAndParent
  pathToValue: pathToValue
  normalizeMapping: normalizeMapping
  processMapping: processMapping
  isArray: isArray
  isFunction: isFunction
  isString: isString
  concat: concat