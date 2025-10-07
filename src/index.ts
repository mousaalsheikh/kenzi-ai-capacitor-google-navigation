import type { PluginListenerHandle } from '@capacitor/core';
import { registerPlugin } from '@capacitor/core';

export type Waypoint = { lat: number; lng: number };

export interface InitOptions {
  /** iOS only (Android reads key from AndroidManifest). */
  iosApiKey?: string;
}

export interface StartOptions {
  originLat?: number;
  originLng?: number;
  destLat: number;
  destLng: number;
  waypoints?: Waypoint[];
  simulate?: boolean;
  /** Android-only header title */
  title?: string;
}

export interface KenziGoogleNavigationPlugin {
  initialize(options?: InitOptions): Promise<{ ok: boolean }>;
  startNavigation(options: StartOptions): Promise<{ started: boolean }>;

  // Events
  addListener(
    eventName: 'navigationClosed',
    listenerFunc: (data: { closed: true }) => void
  ): Promise<PluginListenerHandle>;

  removeAllListeners(): Promise<void>;
}

export const KenziGoogleNavigation = registerPlugin<KenziGoogleNavigationPlugin>(
  'KenziGoogleNavigation'
);

export default KenziGoogleNavigation;
