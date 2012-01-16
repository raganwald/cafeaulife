_ = require('underscore')

root = this

root.mapper = (s_map) ->
  f_map = _.reduce s_map, (acc, value, key) ->
    if _.isFunction(value)
      acc[key] = value
    else if _.isString(value)
      accessors = _.reject(value.split('.'), _.isEmpty)
      acc[key] = (obj) ->
        _.reduce accessors, (acc, attr) ->
          acc[attr]
        ,
          obj
    acc
  ,
    {}

  (obj) ->
    _.reduce f_map, (acc, fn, key) ->
      acc[key] = fn(obj)
      acc
    ,
      {}