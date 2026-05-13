return {
  {
    "vimpostor/vim-tpipeline",
    config = function()
      vim.g.tpipeline_cursormoved = 1
      -- vim.g.tpipeline_autoembed = 0
      -- vim.g.tpipeline_focuslost = 1
      -- vim.g.tpipeline_fillcentre = 0  -- Don't center-fill, gives windows more room
      -- vim.g.tpipeline_size = 1
      -- Reserve space for tmux windows at the start
      -- vim.g.tpipeline_split = 1  -- Split the statusline
    end,
    -- event = "VeryLazy",
  },
}
