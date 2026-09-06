import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.talleresclubabierto.app',
  appName: 'Talleres Club Abierto',
  webDir: 'www',
  server: { androidScheme: 'https' },
  ios: { contentInset: 'automatic' },
  android: { allowMixedContent: false }
};

export default config;
