-- luacheck: globals vim
local acid = require("acid")
local log = require("acid.log").msg
local connections = require("acid.connections")
local commands = require("acid.commands")
local eval = require("acid.ops").eval

local cljhl = {}

local conn_to_key = function(conn)
  return tostring(conn[1]) .. ":" .. tostring(conn[2])
end

cljhl.cache = {}

cljhl.apply = function(msg)
  if msg.status ~= nil then
    return
  elseif msg.err ~= nil then
    log("Can't apply highlight.", msg.err)
    return
  end
  vim.api.nvim_call_function("AsyncCljHighlightExec", {msg.value})
end

cljhl.highlight = function(ns)
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})
  if ns == nil then
    return
  end

  local opts = ""
  if vim.api.nvim_get_var("clojure_highlight_local_vars") == 0 then
    opts = " :local-vars false"
  end

  local payload = eval{code = "(ns-syntax-command '" .. ns .. opts ..")", ns = "async-clj-highlight"}
  acid.run(payload:with_handler(cljhl.apply))
end

cljhl.preload = function(ns)
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})

  if ns == nil then
    return
  end

  local pwd = vim.api.nvim_call_function("getcwd", {})
  local conn = connections.attempt_get(pwd)
  local key = conn_to_key(conn)

  if cljhl.cache[key] ~= nil then
    cljhl.highlight(ns)
  else
    local cmd = commands.preload{files = {"clj/async_clj_highlight.clj"}}[1]
    acid.run(cmd:with_handler(function(data)
      if data.status then
        return
      end
      cljhl.cache[key] = true
      cljhl.highlight(ns)
    end, conn))
  end
end

return cljhl
