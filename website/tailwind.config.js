/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        // Vakil AI brand — from the Flutter app's app_colors.dart
        navy: {
          darkest: "#0A1730",
          dark: "#0F1F3D",
          DEFAULT: "#16274A",
          light: "#1E3157",
          card: "#1B2C52",
        },
        emerald: {
          DEFAULT: "#22C58B",
          dark: "#1AA476",
          soft: "#DFF6EC",
        },
        gold: {
          DEFAULT: "#CBA35C",
          light: "#E4C98A",
        },
        risk: {
          high: "#E15554",
          medium: "#F2A93B",
          low: "#2ECC8F",
        },
        ink: "#14213D",
        inkMuted: "#5B6A8A",
      },
      fontFamily: {
        sans: ["var(--font-jakarta)", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
