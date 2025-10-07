import { registerPlugin } from '@capacitor/core';

export type Waypoint = { lat: number; lng: number };

export interface InitOptions {
  iosApiKey?: string; // (ignored on Android; Android reads key from manifest)
}

export interface StartOptions {
  originLat?: number;
  originLng?: number;
  destLat: number;
  destLng: number;
  waypoints?: Waypoint[];
  simulate?: boolean;
  /** Optional header title shown in the in-app UI (Android only) */
  title?: string;
}

export interface KenziGoogleNavigationPlugin {
  initialize(options?: InitOptions): Promise<{ ok: boolean }>;
  startNavigation(options: StartOptions): Promise<{ started: boolean }>;
}

const KenziGoogleNavigation = registerPlugin<KenziGoogleNavigationPlugin>(
  'KenziGoogleNavigation',
  {
    // Web fallback (no-op) – optional: implement if you like
    web: () => import('./web').then(m => new m.KenziGoogleNavigationWeb()),
  }
);

export default KenziGoogleNavigation;
export { KenziGoogleNavigation };
