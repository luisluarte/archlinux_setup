#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting Minimal R + Neovim + Slime + Tmux Setup..."

# --- 1. Install System Dependencies ---
echo "🔧 Installing system packages (neovim, r, tmux, git, base-devel)..."
sudo pacman -Syu --needed --noconfirm neovim r tmux git base-devel

# Optional: Install clipboard tool (useful for vim-slime/nvim)
# Check if running Wayland or X11 - this is a basic check
clipboard_tool="xclip" # Default to xclip for X11
if [[ -n "$WAYLAND_DISPLAY" ]]; then
  clipboard_tool="wl-clipboard" # wl-copy/wl-paste for Wayland
fi
echo "🔧 Installing clipboard tool ($clipboard_tool)..."
sudo pacman -S --needed --noconfirm "$clipboard_tool"

echo "✅ System packages installed."

# --- 2. Install R Language Server ---
echo "📦 Installing R 'languageserver' package..."
# Use Rscript for non-interactive execution
sudo Rscript -e 'if (!requireNamespace("languageserver", quietly = TRUE)) install.packages("languageserver", repos = "https://cloud.r-project.org/")'
echo "✅ R language server installed."

# --- 3. Setup Neovim Configuration (using lazy.nvim) ---
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_LUA_DIR="$NVIM_CONFIG_DIR/lua"
NVIM_PLUGINS_DIR="$NVIM_LUA_DIR/plugins"

echo "⚙️ Setting up Neovim configuration directories..."
mkdir -p "$NVIM_PLUGINS_DIR"

# --- 3a. Setup lazy.nvim ---
LAZYGIT_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZYGIT_DIR" ]; then
  echo "Cloning lazy.nvim plugin manager..."
  git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZYGIT_DIR"
else
  echo "lazy.nvim already found."
fi

# --- 3b. Create init.lua ---
echo "📝 Creating minimal init.lua..."
cat << 'EOF' > "$NVIM_CONFIG_DIR/init.lua"
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key BEFORE setting up lazy
vim.g.mapleader = " " -- Your leader key definition
vim.g.localleader = " " -- Optional: Set localleader too if you use it

-- Basic Neovim options (can be here or after lazy setup)
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- Load plugins from lua/plugins directory
require("lazy").setup("plugins")

-- Basic Neovim options (optional)
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.g.mapleader = " " -- Set leader key to Space
EOF

# --- 3c. Create R plugins file ---
echo "📝 Creating R plugin configuration (lua/plugins/r-setup.lua)..."
cat << 'EOF' > "$NVIM_PLUGINS_DIR/r-setup.lua"
return {
  -- Syntax Highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- Auto-update parsers
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { "r", "lua", "vim", "vimdoc" }, -- Add R parser
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true, -- Enable highlighting
        },
      })
    end,
  },

  -- REPL Interaction with external terminal via tmux
  {
    "jpalardy/vim-slime",
    config = function()
      vim.g.slime_target = "tmux"
      -- Sends to the next pane relative to the current one
      vim.g.slime_default_config = { socket_name = "default", target_pane = ":.+" }

      -- Keymaps for sending code
      vim.keymap.set("n", "<leader>rl", "<Plug>SlimeLineSend", { desc = "Slime Send Line" })
      vim.keymap.set("v", "<leader>r", "<Plug>SlimeRegionSend", { desc = "Slime Send Visual Selection" }) -- Use <leader>r in visual mode
      vim.keymap.set("n", "<leader>rs", "<Plug>SlimeMotionSend", { desc = "Slime Send Motion" })
      vim.keymap.set("n", "<leader>rp", "<Plug>SlimeParagraphSend", { desc = "Slime Send Paragraph" })
    end,
  },

-- LSP Configuration (Standard Style - Should Work)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",       -- Autocompletion engine
      "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
      -- Mason plugins are likely loaded via the workaround file now
    },
    config = function()
      -- Require lspconfig inside the config function
      local lspconfig = require("lspconfig") 
      -- Get capabilities from nvim-cmp
      local capabilities = require('cmp_nvim_lsp').default_capabilities() 

      -- Define the setup for the R language server using the standard method
      lspconfig.r_language_server.setup({ -- This should be line ~47
          capabilities = capabilities,
          -- Other server-specific settings can go here if needed
      })

      -- Basic LSP keymap 
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = true, desc = "LSP Hover" })
      vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, { buffer = true, desc = "Line Diagnostics"})
    end
  },

-- Completion UI
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        sources = cmp.config.sources({
          { name = "nvim_lsp" }
        }),
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          -- Replace previous Tab/S-Tab mappings with this more standard approach:
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            -- You could add logic here for snippets if using them
            -- elseif require("luasnip").expand_or_jumpable() then
            --   require("luasnip").expand_or_jump()
            else
              fallback() -- Fallback to default Tab behavior if completion isn't visible
            end
          end, { "i", "s" }), -- 'i' for insert mode, 's' for select mode
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            -- You could add logic here for snippet jumping if using them
            -- elseif require("luasnip").jumpable(-1) then
            --   require("luasnip").jump(-1)
            else
              fallback() -- Fallback to default Shift-Tab behavior
            end
          end, { "i", "s" }),
        }),
        experimental = {
          ghost_text = true,
        },
      })
      -- REMOVE the line below if it exists:
      -- _G.cmp_select = require("cmp").mapping.select_opts({ behavior = require("cmp").SelectBehavior.Select })
    end
  },
}
EOF

echo "✅ Neovim configuration files created."
echo ""
echo "--- Installation Complete ---"
echo ""
echo "Next Steps:"
echo "1. Run 'nvim' for the first time. lazy.nvim should automatically install the plugins."
echo "2. If prompted, run ':TSInstall r' inside Neovim to ensure the R parser is installed."
echo "3. Use the 'start_R_dev.sh' script (or manually set up tmux) to start your development session."
echo "   - nvim in one pane, R console in the other."
echo "   - Use your leader key (Space) + 'rl'/'rs'/'rp' or Visual mode + '<leader>r' to send code."
echo "   - Use Ctrl+Space for LSP completion."
