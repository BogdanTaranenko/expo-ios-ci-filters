/**
 * Parses a hex color string into RGBA components (0-1 range).
 * Supports: "#RGB", "#RGBA", "#RRGGBB", "#RRGGBBAA" (with or without #)
 */
export function parseHexColor(hex: string): {
  colorRed: number;
  colorGreen: number;
  colorBlue: number;
  colorAlpha: number;
} | null {
  let h = hex.replace(/^#/, "");

  if (h.length === 3 || h.length === 4) {
    h = h
      .split("")
      .map((c) => c + c)
      .join("");
  }

  if (h.length === 6) {
    h += "FF";
  }

  if (h.length !== 8) {
    return null;
  }

  const num = parseInt(h, 16);
  if (isNaN(num)) {
    return null;
  }

  return {
    colorRed: ((num >> 24) & 0xff) / 255,
    colorGreen: ((num >> 16) & 0xff) / 255,
    colorBlue: ((num >> 8) & 0xff) / 255,
    colorAlpha: (num & 0xff) / 255,
  };
}
