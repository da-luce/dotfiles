local function get_color(group, attr)
    local hl = vim.api.nvim_get_hl_by_name(group, true)
    if attr == "fg#" then
        return string.format("#%06x", hl.foreground)
    elseif attr == "bg#" then
        return string.format("#%06x", hl.background)
    end
end

require 'lualine'.setup {
    sections = {
        lualine_a = {
            {
                'mode',
                icon = { '' },
            },
        },
        lualine_b = {},
        lualine_c = {
            {
                'branch',
                icon = {
                    '',
                    color = { gui = 'bold' },
                },
            },
            {
                'diff',
                source = diff_source,
                symbols = {
                    added = ' ',
                    modified = ' ',
                    removed = ' '
                },
                diff_color = {
                    added = { fg = get_color("DiagnosticSignHint", "fg#"), gui = 'bold' },
                    modified = { fg = get_color("DiagnosticSignInfo", "fg#"), gui = 'bold' },
                    removed = { fg = get_color("DiagnosticSignError", "fg#"), gui = 'bold' },
                },
                colored = true,
            },
        },
        lualine_x = {
            {
                'location',
                icon = {
                    '',
                    align = 'left',
                }
            },
        },
        lualine_y = {},
        lualine_z = {
            {
                'progress',
                icon = {
                    '',
                    align = 'left',
                }
            },
        },
    },
    options = {
        disabled_filetypes = { "dashboard" },
        globalstatus = true,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '|'},
        theme = 'auto',
    },
    extensions = {
        "toggleterm",
        "nvim-tree",
    }
}
