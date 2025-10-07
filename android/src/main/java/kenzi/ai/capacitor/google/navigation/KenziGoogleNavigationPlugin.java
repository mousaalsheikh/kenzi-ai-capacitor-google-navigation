package kenzi.ai.capacitor.google.navigation;

import android.content.Intent;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "KenziGoogleNavigation")
public class KenziGoogleNavigationPlugin extends Plugin {

    // Optional helper from your earlier code; keep if you still use echo()
    private KenziGoogleNavigation implementation = new KenziGoogleNavigation();

    @PluginMethod
    public void initialize(PluginCall call) {
        // Android reads API keys from AndroidManifest <meta-data>, so nothing to do here.
        JSObject ret = new JSObject();
        ret.put("ok", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void startNavigation(PluginCall call) {
        // Required
        Double destLat = call.getDouble("destLat");
        Double destLng = call.getDouble("destLng");

        if (destLat == null || destLng == null) {
            call.reject("destLat and destLng are required");
            return;
        }

        // Optional
        Double originLat = call.getDouble("originLat");
        Double originLng = call.getDouble("originLng");
        boolean simulate = call.getBoolean("simulate", false);
        boolean showHeader = call.getBoolean("showHeader", false);
        String logoUrl = call.getString("logoUrl");               // may be null
        String title = call.getString("title", "Navigation");     // default title

        Intent intent = new Intent(getContext(), NavigationActivity.class);

        // Pass required destination
        intent.putExtra("destLat", destLat);
        intent.putExtra("destLng", destLng);

        // Pass optional origin
        if (originLat != null && originLng != null) {
            intent.putExtra("originLat", originLat);
            intent.putExtra("originLng", originLng);
        }

        // Pass simulate/header/logo/title options
        intent.putExtra("simulate", simulate);
        intent.putExtra("showHeader", showHeader);
        if (logoUrl != null) intent.putExtra("logoUrl", logoUrl);
        intent.putExtra("title", title);

        // Optional waypoints: array of { lat, lng }
        if (call.hasOption("waypoints")) {
            JSArray waypoints = call.getArray("waypoints");
            if (waypoints != null) {
                // NavigationActivity parses this JSON string
                intent.putExtra("waypointsJson", waypoints.toString());
            }
        }

        getActivity().startActivity(intent);

        JSObject ret = new JSObject();
        ret.put("started", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value", "");
        JSObject ret = new JSObject();
        // If you want the old helper behavior:
        if (implementation != null) {
            ret.put("value", implementation.echo(value));
        } else {
            ret.put("value", value);
        }
        call.resolve(ret);
    }
}
