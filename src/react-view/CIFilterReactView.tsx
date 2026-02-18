import * as React from "react";
import { NativeiOSFilterView } from "../view/NativeFilterView.ios";

import type { IReactPropIOS } from "../typings/react-prop/react-prop.ios";
import type { BaseStylingKeyInterface } from "../typings/base/styles";
import type { NativeViewStyleInterface } from "../typings/view/ViewStyle.ios";
import { type ViewStyle } from "react-native";

import { getBorderStyleModifier } from "../config/getBorderStyleModifier";
import { parseHexColor } from "../config/parseHexColor";
import type { OutlineConfig, ShineConfig } from "../typings/react-prop/react-prop.ios";

type InternalProps = IReactPropIOS &
  BaseStylingKeyInterface &
  NativeViewStyleInterface;

export type PublicProps = Omit<InternalProps, "borderRadius"> & {
  style?: ViewStyle;
};

function resolveFilterConfig<T extends OutlineConfig | ShineConfig>(
  config: T | undefined
): Omit<T, "color" | "edgesOnly"> & { edgesOnly?: number } | undefined {
  if (!config) return undefined;
  const { color, ...rest } = config;
  const resolved = { ...rest } as any;

  // Convert hex color to RGBA channels
  if (color) {
    const parsed = parseHexColor(color);
    if (parsed) {
      if (resolved.colorRed === undefined) resolved.colorRed = parsed.colorRed;
      if (resolved.colorGreen === undefined) resolved.colorGreen = parsed.colorGreen;
      if (resolved.colorBlue === undefined) resolved.colorBlue = parsed.colorBlue;
      if (resolved.colorAlpha === undefined) resolved.colorAlpha = parsed.colorAlpha;
    }
  }

  // Convert boolean edgesOnly to number for [String: Double] dict
  if ("edgesOnly" in resolved && typeof resolved.edgesOnly === "boolean") {
    resolved.edgesOnly = resolved.edgesOnly ? 1.0 : 0.0;
  }

  return resolved;
}

export const CIFilterImage: React.FC<PublicProps> &
  React.FunctionComponent<PublicProps> = React.memo(
  (props): React.ReactNode & React.JSX.Element & React.ReactElement => {
    const { style, ...rest } = props;

    const { borderRadius } = getBorderStyleModifier({
      borderRadius: style?.borderRadius ?? (0 as any),
    });
    const cleanedStyle = React.useMemo(() => {
      if (!style) return undefined;
      const { borderRadius: _omit, ...restStyle } = style as ViewStyle;
      return restStyle;
    }, [style]);
    const memoizedProps = React.useMemo(
      () => ({
        ...rest,
        outline: resolveFilterConfig(rest.outline),
        shine: resolveFilterConfig(rest.shine),
        borderRadius,
        style: {
          overflow: "hidden",
          ...(cleanedStyle ?? {}),
        },
      }),
      [rest, borderRadius, cleanedStyle]
    );
    const key = React.useMemo(() => JSON.stringify(props), [props]);
    return <NativeiOSFilterView {...memoizedProps} key={key} />;
  },
  (prevProps, nextProps) =>
    JSON.stringify(prevProps) === JSON.stringify(nextProps)
);
