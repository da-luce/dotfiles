local function get_color(group, attr)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr)
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
