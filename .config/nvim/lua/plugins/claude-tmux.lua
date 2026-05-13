-- ~/.config/nvim/lua/plugins/claude-tmux.lua
return {
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
    config = function()
      local script = vim.fn.expand "~/.local/bin/nvim-to-claude"

      local function tmux_session() return vim.fn.system("tmux display-message -p '#S'"):gsub("%s+", "") end

      local function send_to_claude(file, start_line, end_line)
        local session = tmux_session()
        if session == "" then
          vim.notify("nvim-to-claude: could not get tmux session", vim.log.levels.ERROR)
          return
        end
        local cmd
        if start_line and end_line then
          cmd = string.format("'%s' '%s' '%s' %d %d", script, session, file, start_line, end_line)
        else
          cmd = string.format("'%s' '%s' '%s'", script, session, file)
        end
        local result = vim.fn.system(cmd)
        local exit_code = vim.v.shell_error
        if exit_code ~= 0 then vim.notify("nvim-to-claude failed: " .. result, vim.log.levels.ERROR) end
      end

      vim.keymap.set(
        "n",
        "<leader>ac",
        function() send_to_claude(vim.fn.expand "%:p") end,
        { desc = "Claude: add current file" }
      )
      vim.keymap.set("n", "<leader>al", function()
        local line = vim.fn.line "."
        send_to_claude(vim.fn.expand "%:p", line, line)
      end, { desc = "Claude: add current line" })
      vim.keymap.set("v", "<leader>as", function()
        local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "x", false)
        local start_line = vim.fn.line "'<"
        local end_line = vim.fn.line "'>"
        send_to_claude(vim.fn.expand "%:p", start_line, end_line)
      end, { desc = "Claude: add visual selection" })
      vim.keymap.set(
        "n",
        "<leader>af",
        function() vim.fn.system "tmux select-window -t :claude" end,
        { desc = "Claude: focus tmux window" }
      )
    end,
  },
}
