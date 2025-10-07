package kenzi.ai.capacitor.google.navigation;

import android.content.Intent;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "KenziGoogleNavigation")
public class KenziGoogleNavigationPlugin extends Plugin {

    // ✅ Keep a static reference so activities can access the plugin instance
    private static KenziGoogleNavigationPlugin instance;

    @Override
    public void load() {
        super.load();
        instance = this;
    }

    public static KenziGoogleNavigationPlugin getInstance() {
        return instance;
    }

    /** Called from NavigationActivity when navigation closes */
    public void notifyNavigationClosed() {
        JSObject ret = new JSObject();
        ret.put("closed", true);
        notifyListeners("navigationClosed", ret);
    }

    @PluginMethod
    public void initialize(PluginCall call) {
        // You can optionally handle iOS key setup here later
        JSObject ret = new JSObject();
        ret.put("ok", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void startNavigation(PluginCall call) {
        Double originLat = call.getDouble("originLat");
        Double originLng = call.getDouble("originLng");
        Double destLat   = call.getDouble("destLat");
        Double destLng   = call.getDouble("destLng");
        Boolean simulate = call.getBoolean("simulate", false);
        String title     = call.getString("title", "Navigation");

        if (destLat == null || destLng == null) {
            call.reject("destLat and destLng are required");
            return;
        }

        Intent intent = new Intent(getContext(), NavigationActivity.class);
        if (originLat != null && originLng != null) {
            intent.putExtra("originLat", originLat);
            intent.putExtra("originLng", originLng);
        }
        intent.putExtra("destLat", destLat);
        intent.putExtra("destLng", destLng);
        intent.putExtra("simulate", simulate != null && simulate);
        intent.putExtra("title", title);

        if (call.hasOption("waypoints")) {
            intent.putExtra("waypointsJson", call.getArray("waypoints").toString());
        }

        getActivity().startActivity(intent);
        call.resolve(new JSObject().put("started", true));
    }
}
