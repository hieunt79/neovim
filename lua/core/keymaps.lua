-- core/keymaps.lua
local map = vim.keymap.set

-- NOW WE CAN:
-- - :edit a folder to open a file browser
-- - <CR>/v/t to open in an h-split/v-split/tab
-- - check |netrw-browse-maps| for more mappings
--
-- Use for example `:edit <filename>` to open files in a tree

-- SNIPPETS:
--
-- Read an empty HTML template and move cursor to title
map("n", ",html", ":-1read $HOME/.vim/.skeleton.html<CR>3jwf>a", { noremap = true, silent = true })
-- <CR> is carriage return, without it we would simply type the command into
-- command mode
-- 3jwf>a is how you end up with the cursor in a specific spot, using Vim
-- commands
-- nnoremap is so there is no recursive invocation of ,html
-- -1 in the read command is so it doesn't add a boilerplate line when it adds
-- the snippet

-- NOW WE CAN:
-- - Take over the world!
--   (with much fewer keystrokes)

-- Comment
map("n", "mm", "gcc", { desc = "Toggle comment", remap = true })
map("v", "mm", "gc", { desc = "Toggle comment", remap = true })

vim.opt.statusline = table.concat({
  " %w",                          -- Preview window flag
  " CWD:", "%{getcwd()}",         -- Current working dir
  " Line:%l/%L",                  -- Current line / total lines
  " Column:%c",                   -- Column
  " Filetype:%{&filetype}",       -- Filetype
  " %m",                          -- Modified flag
  " %r",                          -- Readonly flag
  " %w",                          -- Preview window flag again
  " %P"                           -- Position percentage
}, " ")

vim.opt.laststatus = 2

-- Leader key
vim.g.mapleader = ","
-- vim.keymap.set("n", " ", "<leader>")

-- vim.keymap.set("n", "<leader>rl", ":so ~/.config/nvim/init.lua<CR>", { noremap = true })
-- vim.keymap.set("n", "<leader>rl", ":so ~/.config/nvim/init.lua<CR>", { noremap = true, silent = true })
function _G.ReloadConfig()
  for name,_ in pairs(package.loaded) do
    if name:match("^core") or name:match("^plugins") then
      package.loaded[name] = nil
    end
  end
  dofile(vim.fn.stdpath("config") .. "/init.lua")
  print("✨ Reloaded config!")
end

vim.keymap.set("n", "<leader>rl", ReloadConfig, { noremap = true, silent = true })

-- Visual mode: keep selection after indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Insert mode shortcuts
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "kk", "<C-O>")

-- Save, quit, write & quit
vim.keymap.set("n", "<Leader>w", ":w<CR>")
vim.keymap.set("n", "<Leader>q", ":q!<CR>")
vim.keymap.set("n", "<Leader>x", ":x<CR>")

-- Adaptive toggle number settings
vim.opt.number = false
vim.opt.relativenumber = false

-- Toggle number function
function ToggleNumberMode()
  local number = vim.wo.number
  local relativenumber = vim.wo.relativenumber

  if number then
    vim.wo.number = false
    vim.wo.relativenumber = true
  elseif relativenumber then
    vim.wo.relativenumber = false
    vim.wo.number = true
  else
    vim.wo.number = true
  end
end

-- Keybinding to toggle line numbers
vim.keymap.set("n", "<Leader>n", ToggleNumberMode)

-- Toggle visual mode (numbering, statusline, cursorline)
function ToggleVisualMode()
  local number = vim.wo.number
  local relativenumber = vim.wo.relativenumber

  if not number and not relativenumber then
    vim.wo.number = true
    vim.wo.relativenumber = true
    vim.opt.laststatus = 2
    vim.wo.cursorline = true

    vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
      pattern = "*",
      command = "set cursorline",
      group = vim.api.nvim_create_augroup("VisualModeCursorline", { clear = true }),
    })

    vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
      pattern = "*",
      command = "set nocursorline",
      group = vim.api.nvim_create_augroup("VisualModeCursorline", { clear = false }),
    })
  else
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.opt.laststatus = 1
    vim.wo.cursorline = false

    -- Clear autocmds related to cursorline toggle
    vim.api.nvim_clear_autocmds({ group = "VisualModeCursorline" })
  end
end

-- Keymap to toggle visual mode
vim.keymap.set("n", "<Leader>v", ToggleVisualMode, { noremap = true, silent = true })

-- :find with leader key
vim.keymap.set("n", "<Leader>f", ":find ", { noremap = true })

-- Open new tab
vim.keymap.set("n", "<Leader>tn", ":tabnew ", { noremap = true, silent = true })

-- Always show tabline
vim.opt.showtabline = 2

-- Custom tabline
vim.opt.tabline = "%!v:lua.MyTabLine()"

function _G.MyTabLine()
  local s = ""
  local current_tab = vim.fn.tabpagenr()
  local total_tabs = vim.fn.tabpagenr("$")

  for t = 1, total_tabs do
    if t == current_tab then
      s = s .. "%#TabLineSel#"
    else
      s = s .. "%#TabLine#"
    end

    s = s .. "%" .. t .. "T" -- tab switch target
    s = s .. " " .. t .. " "

    local bufnames = ""
    local modified_count = 0
    local buflist = vim.fn.tabpagebuflist(t)
    local bc = #buflist

    for _, b in ipairs(buflist) do
      local buftype = vim.fn.getbufvar(b, "&buftype")
      local name = ""

      if buftype == "help" then
        name = "[H]" .. vim.fn.fnamemodify(vim.fn.bufname(b), ":t"):gsub("%.txt$", "")
      elseif buftype == "quickfix" then
        name = "[Q]"
      else
        name = vim.fn.pathshorten(vim.fn.bufname(b))
      end

      bufnames = bufnames .. name

      if vim.fn.getbufvar(b, "&modified") ~= 0 then
        modified_count = modified_count + 1
      end

      if bc > 1 then
        bufnames = bufnames .. " "
      end
      bc = bc - 1
    end

    if modified_count > 0 then
      s = s .. "[" .. modified_count .. "+]"
    end

    if t == current_tab then
      s = s .. "%#TabLineSel#"
    else
      s = s .. "%#TabLine#"
    end

    if bufnames == "" then
      s = s .. "[New]"
    else
      s = s .. bufnames
    end

    s = s .. " "
  end

  s = s .. "%#TabLineFill#%T"

  if total_tabs > 1 then
    s = s .. "%=%#TabLineFill#%999Xclose"
  end

  return s
end

