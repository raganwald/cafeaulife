_ = require('underscore')

root = this

entity_to_function = (entity)->
  if _.isFunction(entity)
    entity
  else if _.isString(entity)
    accessors = _.reject(entity.split('.'), _.isEmpty)
    if accessors.length is 1
      [attr] = accessors
      (obj) -> obj[attr]
    else if accessors.length is 2
      [attr1, attr2] = accessors
      (obj) -> obj[attr1][attr2]
    else if accessors.length is 3
      [attr1, attr2, attr3] = accessors
      (obj) -> obj[attr1][attr2][attr3]
    else
      (obj) ->
        _.reduce accessors, (acc, attr) ->
          acc[attr]
        ,
          obj
  else if not _.isEmpty(entity)
    sub_m = root.mapper(entity)
    (obj) ->
      sub_m(obj)

root.mapper = (s_map) ->
  f_map = _.reduce s_map, (acc, value, key) ->
    if _.isArray(value)
      fns = value.map(entity_to_function)
      if fns.length is 1
        acc[key] = fns[0]
      else if fns.length is 2
        [x, y] = fns
        acc[key] = (obj) -> x(y(obj))
      else if fns.length is 3
        [x, y, z] = fns
        acc[key] = (obj) -> x(y(z(obj)))
      else if fns.length is 4
        [w, x, y, z] = fns
        acc[key] = (obj) -> w(x(y(z(obj))))
      else
        acc[key] = (obj) ->
          _.reduceRight fns, (acc, fn) ->
            fn(acc)
          ,
            obj
    else
      acc[key] = entity_to_function(value)
    acc
  ,
    {}

  (obj) ->
    _.reduce f_map, (acc, fn, key) ->
      acc[key] = fn(obj)
      acc
    ,
      {}