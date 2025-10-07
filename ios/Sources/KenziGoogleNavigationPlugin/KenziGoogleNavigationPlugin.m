#import <Capacitor/Capacitor.h>

// Registers the Swift plugin class & methods with Capacitor
CAP_PLUGIN(KenziGoogleNavigationPlugin, "KenziGoogleNavigation",
           CAP_PLUGIN_METHOD(initialize, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(startNavigation, CAPPluginReturnPromise);
)
