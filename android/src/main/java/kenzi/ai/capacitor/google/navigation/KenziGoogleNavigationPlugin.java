package kenzi.ai.capacitor.google.navigation;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "KenziGoogleNavigation")
public class KenziGoogleNavigationPlugin extends Plugin {

    @PluginMethod
    public void initialize(PluginCall call) {
        call.resolve(new JSObject().put("ok", true));
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

        // Build intent
        final Intent intent = new Intent(getContext(), NavigationActivity.class);
        if (originLat != null && originLng != null) {
            intent.putExtra("originLat", originLat);
            intent.putExtra("originLng", originLng);
        }
        intent.putExtra("destLat", destLat);
        intent.putExtra("destLng", destLng);
        intent.putExtra("simulate", simulate != null && simulate);
        intent.putExtra("title", title);

        // Optional waypoints
        if (call.hasOption("waypoints")) {
            try {
                JSArray arr = call.getArray("waypoints");
                if (arr != null) {
                    intent.putExtra("waypointsJson", arr.toString());
                }
            } catch (Exception ignored) {}
        }

        // Start activity safely whether or not we have a foreground Activity
        Activity activity = getActivity();
        if (activity != null) {
            activity.runOnUiThread(() -> {
                activity.startActivity(intent);
                call.resolve(new JSObject().put("started", true));
            });
        } else {
            // Fallback: use application context
            Context ctx = getContext();
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            ctx.startActivity(intent);
            call.resolve(new JSObject().put("started", true));
        }
    }
}
