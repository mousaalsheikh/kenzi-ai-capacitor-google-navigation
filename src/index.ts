import { registerPlugin } from '@capacitor/core';

export type Waypoint = { lat: number; lng: number };

export interface InitOptions {
  iosApiKey?: string; // Android reads API key from AndroidManifest
}

export interface StartOptions {
  originLat: number;
  originLng: number;
  destLat: number;
  destLng: number;
  waypoints?: Waypoint[];
  simulate?: boolean;
}

export interface KenziGoogleNavigationPlugin {
  initialize(options: InitOptions): Promise<{ ok: boolean }>;
  startNavigation(options: StartOptions): Promise<{ started: boolean }>;
}

const KenziGoogleNavigation = registerPlugin<KenziGoogleNavigationPlugin>(
  'KenziGoogleNavigation',
  {
    web: () => import('./web').then((m) => new m.KenziGoogleNavigationWeb()),
  }
);

// Default export for easy importing
export default KenziGoogleNavigation;

// Named exports (optional)
export * from './definitions';
export { KenziGoogleNavigation };