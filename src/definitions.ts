export interface KenziGoogleNavigationPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
