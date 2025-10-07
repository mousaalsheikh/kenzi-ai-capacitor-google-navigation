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

  // NEW (Android uses these extras; iOS can ignore)
  showHeader?: boolean;
  logoUrl?: string;
}

export interface KenziGoogleNavigationPlugin {
  initialize(options: InitOptions): Promise<{ ok: boolean }>;
  startNavigation(options: StartOptions): Promise<{ started: boolean }>;
}

const KenziGoogleNavigation = registerPlugin<KenziGoogleNavigationPlugin>(
  'KenziGoogleNavigation',
  {
    web: () => import('./web').then(m => new m.KenziGoogleNavigationWeb()),
  }
);

export default KenziGoogleNavigation;
export { KenziGoogleNavigation };
export * from './definitions'; // keep if you have a separate file
