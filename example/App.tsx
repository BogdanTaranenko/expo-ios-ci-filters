import React, { useState, useEffect, useRef } from "react";
import {
  View,
  Text,
  SafeAreaView,
  TouchableOpacity,
  Animated,
  Dimensions,
  ScrollView,
  StatusBar,
  Alert,
} from "react-native";
import Slider from "@react-native-community/slider";
import { SymbolView } from "expo-symbols";
import { filterGroups, initialFilters } from "./constants";
import * as ImagePicker from "expo-image-picker";
import { CIFilterImage, BlendMode } from "expo-ios-ci-filters";
import { appStyles as styles } from "./styles";
import type { FilterState } from "./FilterState";
const { width, height } = Dimensions.get("window");

const DEFAULT_IMAGE_URL =
  "https://images.pexels.com/photos/1042423/pexels-photo-1042423.jpeg";

export default function CIFilterDemo(): React.JSX.Element {
  const [filters, setFilters] = useState<FilterState>(initialFilters);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<any>(null);
  const [secondaryControl, setSecondaryControl] = useState(false);
  const [currentValue, setCurrentValue] = useState<number>(0);
  const [blendMode, setBlendMode] = useState<BlendMode>(BlendMode.SoftLight);
  const [selectedOutlineColor, setSelectedOutlineColor] = useState<string>("Red");
  const [selectedShineColor, setSelectedShineColor] = useState<string>("White");
  const [imageUri, setImageUri] = useState<string>(DEFAULT_IMAGE_URL);

  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(0)).current;
  const groupSlideAnim = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    StatusBar.setBarStyle("light-content");
    requestPermissions();
  }, []);

  const requestPermissions = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== "granted") {
      Alert.alert(
        "Permission Required",
        "Sorry, we need camera roll permissions to pick images.",
        [{ text: "OK" }]
      );
    }
  };

  const pickImage: VoidFunction = async (): Promise<void | any> => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ["images"],
        allowsEditing: true,
        aspect: [width, height],
        quality: 1,
      });

      if (!result.canceled && result.assets[0]) {
        setImageUri(result.assets[0].uri);
        setFilters(initialFilters);
        setActiveGroup(null);
        setActiveFilter(null);
        setCurrentValue(0);
      }
    } catch (error) {
      Alert.alert("Error", "Failed to pick image");
    }
  };

  const resetToDefaultImage = () => {
    Alert.alert("Reset Image", "Do you want to reset to the default image?", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Reset",
        onPress: () => {
          setImageUri(DEFAULT_IMAGE_URL);
          setFilters(initialFilters);
          setActiveGroup(null);
          setActiveFilter(null);
          setCurrentValue(0);
        },
      },
    ]);
  };

  useEffect(() => {
    Animated.parallel([
      Animated.spring(fadeAnim, {
        toValue: activeFilter ? 1 : 0,
        useNativeDriver: true,
      }),
      Animated.spring(slideAnim, {
        toValue: activeFilter ? 1 : 0,
        useNativeDriver: true,
        tension: 80,
        friction: 12,
      }),
    ]).start();
  }, [activeFilter]);

  useEffect(() => {
    Animated.spring(groupSlideAnim, {
      toValue: activeGroup ? 1 : 0,
      useNativeDriver: true,
      tension: 90,
      friction: 12,
    }).start();
  }, [activeGroup]);

  const handleFilterChange = (
    filterType: keyof FilterState,
    property: string,
    value: number,
    converter: (v: number) => number
  ) => {
    const filterValue = converter(value);

    setFilters((prev) => ({
      ...prev,
      [filterType]: {
        ...prev[filterType],
        [property]: filterValue,
      },
    }));
  };

  const resetAll = () => {
    Animated.sequence([
      Animated.timing(pulseAnim, {
        toValue: 0.95,
        duration: 100,
        useNativeDriver: true,
      }),
      Animated.timing(pulseAnim, {
        toValue: 1,
        duration: 100,
        useNativeDriver: true,
      }),
    ]).start();

    setFilters(initialFilters);
    setActiveGroup(null);
    setActiveFilter(null);
    setCurrentValue(0);
  };

  const hasActiveFilters = Object.values(filters).some(
    (filter) =>
      Object.keys(filter).length > 0 &&
      Object.values(filter).some((v) => v !== 0 && v !== 1 && v !== undefined)
  );

  const activeGroupData = filterGroups.find((g) => g.id === activeGroup);
  const isDefaultImage = imageUri === DEFAULT_IMAGE_URL;

  return (
    <View style={styles.container}>
      <StatusBar
        barStyle="light-content"
        backgroundColor="transparent"
        translucent
      />

      <Animated.View
        style={[styles.imageContainer, { transform: [{ scale: pulseAnim }] }]}
      >
        <CIFilterImage
          url={imageUri}
          style={styles.image}
          {...filters}
          gradientOverlay={
            filters.gradientOverlay?.color0Alpha
              ? { ...filters.gradientOverlay, blendMode }
              : undefined
          }
        />

        <View style={styles.topGradient} />
        <View style={styles.bottomGradient} />

        <TouchableOpacity
          style={styles.imagePickerButton}
          onPress={pickImage}
          activeOpacity={0.7}
        >
          <SymbolView
            name="photo"
            size={20}
            tintColor="#FFFFFF"
            weight="semibold"
          />
        </TouchableOpacity>

        {!isDefaultImage && (
          <TouchableOpacity
            style={styles.resetImageButton}
            onPress={resetToDefaultImage}
            activeOpacity={0.7}
          >
            <SymbolView
              name="arrow.clockwise"
              size={18}
              tintColor="#FFFFFF"
              weight="semibold"
            />
          </TouchableOpacity>
        )}
      </Animated.View>

      <SafeAreaView style={styles.header}>
        <View style={styles.headerContent}>
          <TouchableOpacity style={styles.headerButton} activeOpacity={0.7}>
            <SymbolView
              name="xmark"
              size={20}
              tintColor="#FFFFFF"
              weight="semibold"
            />
          </TouchableOpacity>

          <View style={styles.headerCenter}>
            <Text style={styles.headerTitle}>Edit</Text>
            {(hasActiveFilters || !isDefaultImage) && (
              <View style={styles.editedBadge}>
                <Text style={styles.editedText}>
                  {!isDefaultImage ? "Custom" : "Edited"}
                </Text>
              </View>
            )}
          </View>

          <View style={styles.headerActions}>
            {hasActiveFilters && (
              <TouchableOpacity
                style={[styles.headerButton, styles.resetButton]}
                onPress={resetAll}
                activeOpacity={0.7}
              >
                <Text style={styles.resetText}>Reset</Text>
              </TouchableOpacity>
            )}
            <TouchableOpacity
              style={[styles.headerButton, styles.doneButton]}
              activeOpacity={0.7}
              onPress={() => {
                Alert.alert(
                  "Done",
                  "All changes will be applied to the image.",
                  [
                    {
                      text: "Cancel",
                      style: "cancel",
                    },
                    {
                      text: "OK",
                      onPress: () => {
                        setActiveGroup(null);
                        setActiveFilter(null);
                      },
                    },
                  ]
                );
              }}
            >
              <SymbolView
                name="checkmark"
                size={18}
                tintColor="#000000"
                weight="bold"
              />
            </TouchableOpacity>
          </View>
        </View>
      </SafeAreaView>

      {activeFilter && (
        <Animated.View
          style={[
            styles.valueDisplay,
            {
              opacity: fadeAnim,
              transform: [
                {
                  translateY: fadeAnim.interpolate({
                    inputRange: [0, 1],
                    outputRange: [20, 0],
                  }),
                },
              ],
            },
          ]}
        >
          <Text style={styles.valueLabel}>
            {secondaryControl && activeFilter.secondary
              ? activeFilter.secondary.name
              : activeFilter.name}
          </Text>
          <Text style={styles.valueNumber}>
            {currentValue > 0 ? "+" : ""}
            {Math.round(currentValue)}
          </Text>
        </Animated.View>
      )}

      <View style={styles.bottomPanel}>
        {activeFilter && (
          <Animated.View
            style={[
              styles.controlPanel,
              {
                opacity: fadeAnim,
                transform: [
                  {
                    translateY: slideAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [100, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <View style={styles.sliderSection}>
              <Slider
                style={styles.slider}
                minimumValue={
                  secondaryControl && activeFilter.secondary
                    ? activeFilter.secondary.min
                    : activeFilter.min
                }
                maximumValue={
                  secondaryControl && activeFilter.secondary
                    ? activeFilter.secondary.max
                    : activeFilter.max
                }
                value={currentValue}
                onValueChange={setCurrentValue}
                onSlidingComplete={(value) => {
                  if (secondaryControl && activeFilter.secondary) {
                    handleFilterChange(
                      activeFilter.id as keyof FilterState,
                      activeFilter.secondary.property,
                      value,
                      activeFilter.secondary.converter
                    );
                  } else {
                    handleFilterChange(
                      activeFilter.id as keyof FilterState,
                      activeFilter.property,
                      value,
                      activeFilter.converter
                    );
                  }
                }}
                minimumTrackTintColor="#FFD700"
                maximumTrackTintColor="rgba(255, 255, 255, 0.15)"
                thumbTintColor="#FFFFFF"
                tapToSeek={false}
              />
              <View style={styles.sliderScale}>
                <View style={[styles.scaleMark, styles.scaleMarkCenter]} />
              </View>
            </View>

            {activeFilter.secondary && (
              <View style={styles.secondaryControls}>
                <TouchableOpacity
                  style={[
                    styles.secondaryButton,
                    !secondaryControl && styles.secondaryButtonActive,
                  ]}
                  onPress={() => {
                    setSecondaryControl(false);
                    setCurrentValue(activeFilter.default);
                  }}
                >
                  <Text
                    style={[
                      styles.secondaryButtonText,
                      !secondaryControl && styles.secondaryButtonTextActive,
                    ]}
                  >
                    {activeFilter.name}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.secondaryButton,
                    secondaryControl && styles.secondaryButtonActive,
                  ]}
                  onPress={() => {
                    setSecondaryControl(true);
                    setCurrentValue(activeFilter.secondary.default);
                  }}
                >
                  <Text
                    style={[
                      styles.secondaryButtonText,
                      secondaryControl && styles.secondaryButtonTextActive,
                    ]}
                  >
                    {activeFilter.secondary.name}
                  </Text>
                </TouchableOpacity>
              </View>
            )}

            {activeFilter.presets && (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.presetsContainer}
              >
                {activeFilter.presets.map((preset: any) => {
                  const isActive = preset.blendMode
                    ? blendMode === preset.blendMode
                    : activeFilter?.id === "shine"
                      ? selectedShineColor === preset.name
                      : selectedOutlineColor === preset.name;

                  return (
                    <TouchableOpacity
                      key={preset.name}
                      style={[
                        styles.presetButton,
                        isActive && styles.presetButtonActive,
                      ]}
                      onPress={() => {
                        if (preset.blendMode) {
                          setBlendMode(preset.blendMode);
                        } else if (activeFilter?.id === "shine") {
                          setSelectedShineColor(preset.name);
                          setFilters((prev) => ({
                            ...prev,
                            shine: {
                              ...prev.shine,
                              colorRed: preset.colorRed ?? prev.shine.colorRed ?? 1,
                              colorGreen: preset.colorGreen ?? prev.shine.colorGreen ?? 1,
                              colorBlue: preset.colorBlue ?? prev.shine.colorBlue ?? 1,
                            },
                          }));
                        } else {
                          setSelectedOutlineColor(preset.name);
                          setFilters((prev) => ({
                            ...prev,
                            outline: {
                              ...prev.outline,
                              colorRed: preset.colorRed ?? prev.outline.colorRed ?? 0,
                              colorGreen: preset.colorGreen ?? prev.outline.colorGreen ?? 0,
                              colorBlue: preset.colorBlue ?? prev.outline.colorBlue ?? 0,
                            },
                          }));
                        }
                      }}
                    >
                      <Text
                        style={[
                          styles.presetText,
                          isActive && styles.presetTextActive,
                        ]}
                      >
                        {preset.name}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </ScrollView>
            )}
          </Animated.View>
        )}

        {activeGroup && (
          <Animated.View
            style={[
              styles.filtersList,
              {
                opacity: groupSlideAnim,
                transform: [
                  {
                    translateY: groupSlideAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [50, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.filtersContainer}
            >
              {activeGroupData?.filters.map((filter) => {
                const filterValue = (
                  filters[filter.id as keyof FilterState] as any
                )?.[filter.property];
                const hasValue =
                  filterValue !== undefined &&
                  filterValue !== 0 &&
                  filterValue !== 1;

                return (
                  <TouchableOpacity
                    key={`${filter.id}-${filter.property}`}
                    style={[
                      styles.filterItem,
                      activeFilter?.property === filter.property &&
                        styles.filterItemActive,
                    ]}
                    onPress={() => {
                      if (activeFilter?.property === filter.property) {
                        setActiveFilter(null);
                        setSecondaryControl(false);
                      } else {
                        setActiveFilter(filter);
                        setSecondaryControl(false);
                        setCurrentValue(filter.default);
                      }
                    }}
                  >
                    <View
                      style={[
                        styles.filterIconBox,
                        activeFilter?.property === filter.property &&
                          styles.filterIconBoxActive,
                        hasValue && styles.filterIconBoxEdited,
                      ]}
                    >
                      <SymbolView
                        name={filter.icon}
                        size={20}
                        tintColor={
                          activeFilter?.property === filter.property
                            ? "#000000"
                            : hasValue
                              ? "#FFD700"
                              : "rgba(255, 255, 255, 0.8)"
                        }
                        weight="medium"
                      />
                    </View>
                    <Text
                      style={[
                        styles.filterName,
                        activeFilter?.property === filter.property &&
                          styles.filterNameActive,
                        hasValue && styles.filterNameEdited,
                      ]}
                    >
                      {filter.name}
                    </Text>
                    {hasValue && activeFilter?.property !== filter.property && (
                      <View style={styles.editedDot} />
                    )}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </Animated.View>
        )}

        <View style={styles.toolGroups}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.toolGroupsContainer}
          >
            {filterGroups.map((group) => (
              <TouchableOpacity
                key={group.id}
                style={[
                  styles.toolGroup,
                  activeGroup === group.id && styles.toolGroupActive,
                ]}
                onPress={() => {
                  setActiveGroup(activeGroup === group.id ? null : group.id);
                  setActiveFilter(null);
                }}
              >
                <View
                  style={[
                    styles.toolGroupIcon,
                    activeGroup === group.id && styles.toolGroupIconActive,
                  ]}
                >
                  <SymbolView
                    name={group.icon}
                    size={24}
                    tintColor={activeGroup === group.id ? "#000000" : "#FFFFFF"}
                    weight={activeGroup === group.id ? "semibold" : "regular"}
                  />
                </View>
                <Text
                  style={[
                    styles.toolGroupName,
                    activeGroup === group.id && styles.toolGroupNameActive,
                  ]}
                >
                  {group.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      </View>
    </View>
  );
}
