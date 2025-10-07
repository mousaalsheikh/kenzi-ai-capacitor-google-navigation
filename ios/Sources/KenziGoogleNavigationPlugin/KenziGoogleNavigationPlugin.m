#import <Capacitor/Capacitor.h>

CAP_PLUGIN(KenziGoogleNavigationPlugin, "KenziGoogleNavigation",
  CAP_PLUGIN_METHOD(initialize, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(startNavigation, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(close, CAPPluginReturnNone);
  CAP_PLUGIN_METHOD(isGoogleMapsInstalled, CAPPluginReturnPromise);
)
