module.exports = {
    content: [
        "Resources/Views/*.leaf",
        "Resources/Views/*/*.leaf",
        "Resources/Views/*/*/*.leaf",
    ],
    darkMode: 'media',
    theme: {
        extend: {},
        fontFamily: {
            'display': ['Noto Sans', 'system-ui']
        },
        colors: {
            'white': '#FFFFFF',
            'transparent': 'transparent',
            'plasma-blue': {
                DEFAULT: '#3DAEE9',
                '50': '#E2F3FC',
                '100': '#D0EBFA',
                '200': '#ABDCF5',
                '300': '#86CDF1',
                '400': '#62BDED',
                '500': '#3DAEE9',
                '600': '#1895D6',
                '700': '#1372A3',
                '800': '#0D4F71',
                '900': '#072B3F'
            },
            'stone': {
                DEFAULT: '#686B6F',
                '50': '#AEB0B3',
                '100': '#A6A8AC',
                '200': '#96999D',
                '300': '#868A8E',
                '400': '#777A7F',
                '500': '#686B6F',
                '600': '#595C5F',
                '700': '#4A4D4F',
                '800': '#3C3D40',
                '900': '#2D2E30'
            },
            'cloud': {
                DEFAULT: '#D1D5D9',
                '50': '#F7F7F8',
                '100': '#F3F4F5',
                '200': '#EAECEE',
                '300': '#E2E4E7',
                '400': '#D9DDE0',
                '500': '#D1D5D9',
                '600': '#C3C8CD',
                '700': '#B5BBC2',
                '800': '#A7AFB6',
                '900': '#99A2AB'
            },
            'charcoal': {
                DEFAULT: '#2E3134',
                '50': '#6F767D',
                '100': '#676E75',
                '200': '#595F65',
                '300': '#4B5054',
                '400': '#3C4044',
                '500': '#2E3134',
                '600': '#242729',
                '700': '#1B1D1E',
                '800': '#111214',
                '900': '#080809'
            },
        }
    },
    variants: {},
    plugins: [
        require('@tailwindcss/typography'),
    ],
}
