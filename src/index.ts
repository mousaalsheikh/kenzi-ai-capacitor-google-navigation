import { registerPlugin } from '@capacitor/core';

import type { KenziGoogleNavigationPlugin } from './definitions';

const KenziGoogleNavigation = registerPlugin<KenziGoogleNavigationPlugin>('KenziGoogleNavigation', {
  web: () => import('./web').then((m) => new m.KenziGoogleNavigationWeb()),
});

export * from './definitions';
export { KenziGoogleNavigation };
