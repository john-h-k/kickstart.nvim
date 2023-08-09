--[[

# John's vim configuration

Originally I used `kickstart.nvim`, before moving onto a customised `LazyVim` setup.
`LazyVim` was great, but kind of bugprone and overwhelming honestly, so I have gone back to `kickstart.nvim`.

I have split it up much more than the original `kickstart` to give a more modular feel.

--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Load vim options before plugins
require("opts")

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
    -- NOTE: First, some plugins that don't require any configuration
    'mg979/vim-visual-multi',

    -- Git related plugins
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',

    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- For surround matching
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    },

    {
        -- Set lualine as statusline
        'nvim-lualine/lualine.nvim',
        -- See `:help lualine.txt`
        opts = {
            options = {
                icons_enabled = false,
                theme = 'onedark',
                component_separators = '|',
                section_separators = '',
            },
        },
    },

    {
        -- Add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help indent_blankline.txt`
        opts = {
            char = '┊',
            show_trailing_blankline_indent = false,
        },
    },

    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },

    'simrat39/rust-tools.nvim',

    -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
    --       These are some example plugins that I've included in the kickstart repository.
    --       Uncomment any of the lines below to enable them.
    -- require 'kickstart.plugins.autoformat',
    -- require 'kickstart.plugins.debug',

    -- NOTE: The import below automatically adds your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
    --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
    --    up-to-date with whatever is in the kickstart repo.
    --
    --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
    { import = 'plugins' },
}, {})

-- Now plugins are available, load keymaps
require("keymap")

-- Ruby configuration
vim.api.nvim_create_autocmd("FileType", {
    pattern = "ruby",
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
    end
})

-- [[ Custom Commands ]]

function _G.split_at_first(str, sep)
    local sep_pos = str:find(sep, 1, true)
    if sep_pos then
        local first = str:sub(1, sep_pos - 1)
        local rest = str:sub(sep_pos + #sep)
        return {first, rest}
    else
        return {str}
    end
end

function _G.OptTransformLines(start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local transformed_lines = {}

    -- A pattern that matches a Rust struct field.
    local no_pub_pattern = "^%s*%w+%s*:%s*[^/]+%s*,?$"
    local pub_pattern = "^%s*pub([^)]*)%s?%w+%s*:%s*[^/]+%s*,?$"

    for _, line in ipairs(lines) do        -- Check if the line matches the pattern.
        if not string.match(line, pub_pattern) and not string.match(line, no_pub_pattern) then
            -- Just ignore
            table.insert(transformed_lines, line)
            goto loop_end
        end

        -- split the line on ':'
        local split_line = split_at_first(line, ':')
        -- get the field name and field type
        local split_field = vim.split(split_line[2], '//')
        local field = vim.fn.trim(split_field[1], ' ,')
        local comment = split_field[2]

        if comment ~= nil then
            comment = ' // ' .. comment
        else
            comment = ''
        end

        -- add the transformed line to the list
        table.insert(transformed_lines, split_line[1] .. ': Option<' .. field .. '>,' .. comment)

        ::loop_end::
    end

    -- replace the lines in the buffer
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, transformed_lines)
end

vim.cmd("command! -range Opt lua _G.OptTransformLines(<line1>, <line2>)")

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
