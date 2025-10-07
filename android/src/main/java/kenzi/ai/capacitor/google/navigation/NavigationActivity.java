package kenzi.ai.capacitor.google.navigation;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;

import com.google.android.libraries.navigation.ListenableResultFuture;
import com.google.android.libraries.navigation.NavigationApi;
import com.google.android.libraries.navigation.Navigator;
import com.google.android.libraries.navigation.SupportNavigationFragment;
import com.google.android.libraries.navigation.Waypoint;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class NavigationActivity extends AppCompatActivity {

    private Navigator navigator;

    // store base paddings so insets don’t compound
    private int baseRootPadLeft, baseRootPadTop, baseRootPadRight, baseRootPadBottom;
    private int baseHeaderPadLeft, baseHeaderPadTop, baseHeaderPadRight, baseHeaderPadBottom;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_navigation);

        View root = findViewById(R.id.root);
        View header = findViewById(R.id.header);
        TextView titleView = findViewById(R.id.title);
        ImageButton btnClose = findViewById(R.id.btn_close);

        // ---- title: from saved state, else from intent, else app label, else
        // "Navigation"
        String titleText = null;
        // if (savedInstanceState != null) {
        // titleText = savedInstanceState.getString(KEY_TITLE);
        // }
        if (titleText == null) {
            titleText = getIntent().getStringExtra("title");
        }
        if (titleText == null || titleText.trim().isEmpty()) {
            // app label fallback
            try {
                CharSequence appLabel = getPackageManager().getApplicationLabel(getApplicationInfo());
                if (appLabel != null && appLabel.length() > 0) {
                    titleText = appLabel.toString();
                }
            } catch (Exception ignored) {
            }
        }
        if (titleText == null || titleText.trim().isEmpty()) {
            titleText = "Navigation";
        }
        titleView.setText(titleText);
        // ---- end title

        // Insets listener (unchanged)
        ViewCompat.setOnApplyWindowInsetsListener(root, (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            header.setPadding(
                    header.getPaddingLeft(),
                    bars.top, // header sits below status bar
                    header.getPaddingRight(),
                    header.getPaddingBottom());
            v.setPadding(bars.left, 0, bars.right, bars.bottom);
            return insets;
        });

        // Fragment
        SupportNavigationFragment fragment = SupportNavigationFragment.newInstance();
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.nav_container, fragment)
                .commitNow();

        btnClose.setOnClickListener(v -> stopAndFinish());

        NavigationApi.getNavigator(
                this,
                new NavigationApi.NavigatorListener() {
                    @Override
                    public void onNavigatorReady(Navigator nav) {
                        navigator = nav;
                        startGuidanceFlow();
                    }

                    @Override
                    public void onError(int errorCode) {
                        finish();
                    }
                });
    }

    private String resolveTitle() {
        try {
            CharSequence appLabel = getPackageManager().getApplicationLabel(getApplicationInfo());
            if (appLabel != null && appLabel.length() > 0) {
                return appLabel.toString();
            }
        } catch (Exception ignored) {
        }
        return "Navigation";
    }

    @Override
    protected void onResume() {
        super.onResume();
        // re-ask for insets after unlock/config changes
        View root = findViewById(R.id.root);
        ViewCompat.requestApplyInsets(root);
    }

    private void startGuidanceFlow() {
        if (navigator == null) {
            finish();
            return;
        }

        boolean simulate = getIntent().getBooleanExtra("simulate", false);
        List<Waypoint> waypoints = new ArrayList<>();

        if (getIntent().hasExtra("originLat") && getIntent().hasExtra("originLng")) {
            double oLat = getIntent().getDoubleExtra("originLat", 0);
            double oLng = getIntent().getDoubleExtra("originLng", 0);
            waypoints.add(Waypoint.builder().setLatLng(oLat, oLng).build());
        }

        if (getIntent().hasExtra("waypointsJson")) {
            try {
                JSONArray arr = new JSONArray(getIntent().getStringExtra("waypointsJson"));
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject o = arr.getJSONObject(i);
                    waypoints.add(Waypoint.builder()
                            .setLatLng(o.getDouble("lat"), o.getDouble("lng"))
                            .build());
                }
            } catch (Exception ignored) {
            }
        }

        double dLat = getIntent().getDoubleExtra("destLat", 0);
        double dLng = getIntent().getDoubleExtra("destLng", 0);
        waypoints.add(Waypoint.builder().setLatLng(dLat, dLng).build());

        ListenableResultFuture<Navigator.RouteStatus> future = navigator.setDestinations(waypoints);
        future.setOnResultListener(code -> {
            if (code == Navigator.RouteStatus.OK) {
                if (simulate) {
                    navigator.getSimulator().simulateLocationsAlongExistingRoute();
                }
                navigator.startGuidance();
            } else {
                finish();
            }
        });
    }

    private void stopAndFinish() {
        try {
            if (navigator != null) {
                navigator.stopGuidance();
                navigator.clearDestinations();
            }
        } catch (Exception ignored) {
        }

        // 🔔 Notify plugin listeners
        KenziGoogleNavigationPlugin plugin = KenziGoogleNavigationPlugin.getInstance();
        if (plugin != null) {
            plugin.notifyNavigationClosed();
        }

        finish();
    }

    @Override
    public void onBackPressed() {
        stopAndFinish();
    }

    @Override
    protected void onDestroy() {
        stopAndFinish();
        super.onDestroy();
    }
}
