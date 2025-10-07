package kenzi.ai.capacitor.google.navigation;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;

import com.bumptech.glide.Glide;
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

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_navigation);

        View root = findViewById(R.id.root);
        View header = findViewById(R.id.header);

        // Prevent overlap with status bar / navigation bar
        ViewCompat.setOnApplyWindowInsetsListener(root, (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            header.setPadding(
                    header.getPaddingLeft(),
                    header.getPaddingTop() + bars.top,
                    header.getPaddingRight(),
                    header.getPaddingBottom()
            );
            v.setPadding(bars.left, 0, bars.right, bars.bottom);
            return insets;
        });

        // Add the navigation fragment
        SupportNavigationFragment fragment = SupportNavigationFragment.newInstance();
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.nav_container, fragment)
                .commitNow();

        ImageButton btnClose = findViewById(R.id.btn_close);
        ImageView logo = findViewById(R.id.logo);

        boolean showHeader = getIntent().getBooleanExtra("showHeader", true);
        String logoUrl = getIntent().getStringExtra("logoUrl");

        header.setVisibility(showHeader ? View.VISIBLE : View.GONE);
        if (showHeader && logoUrl != null && !logoUrl.isEmpty()) {
            Glide.with(this).load(logoUrl).into(logo);
        }

        // Close button stops guidance and exits
        btnClose.setOnClickListener(v -> stopAndFinish());

        // Initialize the navigator
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
            } catch (Exception ignored) { }
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
        } catch (Exception ignored) { }
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
