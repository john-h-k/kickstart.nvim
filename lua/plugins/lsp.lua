return {
    {
        -- LSP Configuration & Plugins
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Automatically install LSPs to stdpath for neovim
            {
                'williamboman/mason.nvim',
                config = true
            },
            'williamboman/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
            { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

            -- Additional lua configuration, makes nvim stuff amazing!
            'folke/neodev.nvim',
        },

        config = function(_, opts)
            -- [[ Configure LSP ]]
            --  This function gets run when an LSP connects to a particular buffer.
            local on_attach = function(_, bufnr)
                -- NOTE: Remember that lua is a real programming language, and as such it is possible
                -- to define small helper and utility functions so you don't have to repeat yourself
                -- many times.
                --
                -- In this case, we create a function that lets us more easily define mappings specific
                -- for LSP related items. It sets the mode, buffer and description for us each time.
                local nmap = function(keys, func, desc)
                    if desc then
                        desc = 'LSP: ' .. desc
                    end

                    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
                end

                nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

                -- Use <leader>a instead of <leader>ca for code actions as it is very common
                nmap('<leader>a', vim.lsp.buf.code_action, '[C]ode [A]ction')

                nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
                nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
                nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
                nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
                nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

                -- See `:help K` for why this keymap
                nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
                nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

                -- Lesser used LSP functionality
                nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
                nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
                nmap('<leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, '[W]orkspace [L]ist Folders')

                -- Create a command `:Format` local to the LSP buffer
                vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
                    vim.lsp.buf.format()
                end, { desc = 'Format current buffer with LSP' })
            end

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. They will be passed to
            --  the `settings` field of the server config. You must look up that documentation yourself.
            local nvim_lsp = require('lspconfig')
            local servers = {
                -- clangd = {},
                -- gopls = {},
                -- pyright = {},

                -- rust_analyzer is managed by the `rust-tools` plugin
                -- rust_analyzer = {},
                omnisharp = {},
                solargraph = {
                    solargraph = {
                        bundlerPath = os.getenv( "HOME" ) .. "/.rbenv/shims/bundle",
                        useBundler = true,
                    }
                },
                -- tsserver = {},

                lua_ls = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            }

            -- Setup neovim lua configuration
            require('neodev').setup()

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            -- Ensure the servers above are installed
            -- makes sure the language servers configured later with lspconfig are
            -- actually available, and install them automatically if they're not
            -- !! THIS MUST BE CALLED BEFORE ANY LANGUAGE SERVER CONFIGURATION
            require("mason").setup()
            local mason_lspconfig = require("mason-lspconfig")

            mason_lspconfig.setup {
                -- automatically install language servers for `nvim-lspconfig`
                -- EXCEPT `rust_analyzer` (managed by `rust-tools` + `cargo`) and `solargraph` (managed by `bundle`)
                automatic_installation = { exclude = { "rust_analyzer", "solargraph" } }
            }

            -- nvim_lsp.solargraph.setup {
            --     cmd = { os.getenv( "HOME" ) .. "/.rbenv/shims/bundle", "solargraph", "stdio" },
            --     root_dir = nvim_lsp.util.root_pattern("Gemfile", ".git", "."),
            --     settings = {
            --       solargraph = {
            --         autoformat = true,
            --         completion = true,
            --         diagnostic = true,
            --         folding = true,
            --         references = true,
            --         rename = true,
            --         symbols = true
            --       }
            --     }
            -- }

            mason_lspconfig.setup_handlers {
                function(server_name)
                    require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                    }
                end,
            }
        end
    },

    {
        'simrat39/rust-tools.nvim',
        opts = {
            -- [[ rust-tools configuration ]]
            --
            -- Configure LSP through rust-tools.nvim plugin.
            -- rust-tools will configure and enable certain LSP features for us.
            -- See https://github.com/simrat39/rust-tools.nvim#configuration
            tools = {
                autoSetHints = true,
                runnables = {
                    use_telescope = true,
                },
                inlay_hints = {
                    auto = true,
                    show_parameter_hints = false,
                    parameter_hints_prefix = "",
                    other_hints_prefix = "",
                },
            },

            -- all the opts to send to nvim-lspconfig
            -- these override the defaults set by rust-tools.nvim
            -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
            server = {
                -- on_attach is a callback called when the language server attachs to the buffer
                on_attach = on_attach,
                settings = {
                    -- to enable rust-analyzer settings visit:
                    -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
                    ["rust-analyzer"] = {
                        -- enable clippy on save
                        checkOnSave = {
                            command = "clippy",
                        },
                    },
                },
            },
        }
    }
}
