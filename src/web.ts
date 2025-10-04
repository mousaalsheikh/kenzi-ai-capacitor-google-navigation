import { WebPlugin } from '@capacitor/core';

import type { KenziGoogleNavigationPlugin } from './definitions';

export class KenziGoogleNavigationWeb extends WebPlugin implements KenziGoogleNavigationPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
