-- Copilot
-- NOTE: github's copilot plugin doesn't integrate with nvim-cmp, so we use an alternative instead
-- 'github/copilot.vim',

return {
    "zbirenbaum/copilot-cmp",

    dependencies = {
        {
            "zbirenbaum/copilot.lua",
            enabled = true,
            cmd = "Copilot",
            event = "InsertEnter",
            opts = {
                suggestion = { enabled = false },
                panel = { enabled = false },
            },
        },
    },

    config = function ()
        require("copilot_cmp").setup()
    end
}
