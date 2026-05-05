return {
  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    config = function(_, opts)
      require("crates").setup(opts)

      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("CmpSourceCargo", { clear = true }),
        pattern = "Cargo.toml",
        callback = function()
          local ok, cmp = pcall(require, "cmp")
          if not ok then return end
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "crates" },
              { name = "luasnip" },
              { name = "path" },
            }, {
              { name = "buffer", keyword_length = 3 },
            }),
          })
        end,
      })

      local map = function(keys, fn, desc)
        vim.keymap.set("n", keys, fn, { desc = desc })
      end

      map("<leader>rcu", function() require("crates").update_crate() end, "Update crate")
      map("<leader>rca", function() require("crates").update_all_crates() end, "Update all crates")
      map("<leader>rcU", function() require("crates").upgrade_crate() end, "Upgrade crate")
      map("<leader>rcA", function() require("crates").upgrade_all_crates() end, "Upgrade all crates")
      map("<leader>rcv", function() require("crates").show_versions_popup() end, "Show crate versions")
      map("<leader>rcf", function() require("crates").show_features_popup() end, "Show crate features")
      map("<leader>rcd", function() require("crates").show_dependencies_popup() end, "Show crate dependencies")
    end,
  },
}
