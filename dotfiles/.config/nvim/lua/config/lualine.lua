local function get_color(group, attr)
    -- attr should be "fg" or "bg"
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    local color = hl[attr]
    
    if not color then
        return nil
    end

    -- nvim_get_hl returns a decimal number, so we convert it to a hex string for Lualine
    return string.format("#%06x", color)
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
