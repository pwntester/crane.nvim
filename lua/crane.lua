local _, Job = pcall(require,'plenary.job')

local M = {}

function M.setup()
  vim.cmd [[augroup Crane]]
  vim.cmd [[  au!]]
  vim.cmd [[  au BufReadCmd docker://* lua require'crane'.load_buffer()]]
  vim.cmd [[  au BufWriteCmd docker://* lua require'crane'.save_buffer()]]
  vim.cmd [[augroup END]]
end

function M.load_buffer()
  -- e docker://pages/build/vendor/gems/ruby/2.7.0/gems/jekyll-3.9.0/lib/jekyll/entry_filter.rb
  local bufname = vim.fn.bufname()
  local bufnr = vim.api.nvim_get_current_buf()
  local tmpdir = vim.fn.fnamemodify(vim.fn.tempname(),":p:h")
  local container, path = string.match(bufname, "docker://([^/]+)(.*)")
  local fname = vim.fn.fnamemodify(path, ":t")
  local src = string.format("%s:%s", container, path)
  local job = Job:new({
    enable_recording = true,
    command = "docker",
    args = {"cp", src, tmpdir},
    on_exit = vim.schedule_wrap(
      function()
        local lines = vim.fn.readfile(tmpdir.."/"..fname)
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
        vim.cmd('doau BufEnter')
        pcall(vim.cmd, 'filetype detect')
        vim.api.nvim_buf_set_option(bufnr, "modified", false)
        vim.cmd('normal gg')
      end
    )
  })
  job:start()
end

function M.save_buffer()
  local bufname = vim.fn.bufname()
  local bufnr = vim.api.nvim_get_current_buf()
  local container, path = string.match(bufname, "docker://([^/]+)(.*)")
  local dest = string.format("%s:%s", container, path)
  local tmpfile = vim.fn.tempname()
  vim.cmd("write "..tmpfile)
  local job = Job:new({
    enable_recording = true,
    command = "docker",
    args = {"cp", tmpfile, dest},
    on_exit = vim.schedule_wrap(
      function()
        vim.api.nvim_buf_set_option(bufnr, "modified", false)
      end
    )
  })
  job:start()
end

return M
