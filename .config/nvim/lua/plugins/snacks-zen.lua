return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.zen = vim.tbl_deep_extend("force", opts.zen or {}, {
      win = {
        backdrop = { transparent = false },
        width = 0.75,
        wo = {
          number = true,
          relativenumber = true,
        },
      },
    })
  end,
}
