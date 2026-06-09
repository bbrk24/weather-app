package com.bbrk24.weatherapp

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.location.provider.ProviderProperties
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.activity.result.contract.ActivityResultContracts

class LocationHandler(private val activity: FragmentActivity) {
    companion object {
        private const val SHARED_PREFERENCE_FILE_NAME = "weatherApp"
        private const val SHARED_PREFERENCE_REQUESTED_PERMISSION_KEY = "hasRequestedPermission"
        
        private const val TAG = "LocationHandler"
    }
    
    private val permissionLauncher = activity.registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
        ::requestLocationPart2
    )

    private val packageManager by lazy { activity.packageManager }

    private val locationManager by lazy {
        activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }
    
    private val sharedPreferences =
        activity.getSharedPreferences(SHARED_PREFERENCE_FILE_NAME, Context.MODE_PRIVATE)
    
    private var hasRequestedPermission: Boolean
        get() = sharedPreferences.getBoolean(SHARED_PREFERENCE_REQUESTED_PERMISSION_KEY, false)
        set(value) {
            sharedPreferences.edit()
                .putBoolean(SHARED_PREFERENCE_REQUESTED_PERMISSION_KEY, value)
                .apply()
        }
    
    var swiftCallbackPointer = 0L

    fun hasLocationFeature() = packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION)

    fun shouldEnableButton(): Boolean {
        if (!hasRequestedPermission) return true
        return when (activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)) {
            PackageManager.PERMISSION_GRANTED ->
                locationManager.isLocationEnabled && locationManager.getProviders(true).isNotEmpty()

            PackageManager.PERMISSION_DENIED -> false

            else -> true
        }
    }

    fun requestLocation() {
        Log.v(TAG, "requestLocation() start")
        if (!hasRequestedPermission) {
            permissionLauncher.launch(Manifest.permission.ACCESS_COARSE_LOCATION)
            hasRequestedPermission = true
        } else {
            requestLocationPart2(
                activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            )
        }
        Log.v(TAG, "requestLocation() end")
    }

    private fun requestLocationPart2(hasPermission: Boolean) {
        Log.v(TAG, "requestLocationPart2() start")
        if (!hasPermission) {
            Log.d(TAG, "permission denied")
            onLocationResult(null, "Permission denied")
            return
        }

        val eligibleProviders = locationManager.getProviders(true)
            .map { it to locationManager.getProviderProperties(it) }
            .filter { it.second != null }
            .map { it.first to it.second!! }

        Log.d(TAG, "eligibleProviders = " + eligibleProviders.joinToString())

        if (eligibleProviders.isEmpty()) {
            onLocationResult(null, "No available location providers")
            return
        }

        try {
            val orderedProviders = eligibleProviders.sortedBy {
                val properties = it.second

                if (it.first == LocationManager.PASSIVE_PROVIDER) {
                    // PASSIVE_PROVIDER only gives you a location if another app
                    // also requests a location fix
                    1 shl 5
                } else {
                    if (properties.hasMonetaryCost()) { 1 shl 4 } else { 0 } or
                    when (properties.powerUsage) {
                        ProviderProperties.POWER_USAGE_HIGH -> 1 shl 3
                        ProviderProperties.POWER_USAGE_MEDIUM -> 1 shl 2
                        ProviderProperties.POWER_USAGE_LOW -> 0
                        else -> (1 shl 3) or (1 shl 2)
                    } or
                    if (properties.hasCellRequirement()) { 1 shl 1 } else { 0 } or
                    if (properties.hasNetworkRequirement()) { 1 shl 0 } else { 0 }
                }
            }.map { it.first }
            
            
            requestLocationPart3(orderedProviders)
        } catch (e: RuntimeException) {
            onLocationResult(null, e.message)
        }
    }

    private fun requestLocationPart3(orderedProviders: List<String>, index: Int = 0) {
        if (index >= orderedProviders.size) {
            onLocationResult(null, null)
            return
        }
    
        val provider = orderedProviders[index]

        try {
            Log.d(TAG, "Attempting provider $provider...")
            locationManager.getCurrentLocation(
                provider,
                null,
                { it.run() },
                {
                    Log.v(TAG, "location = $it")
                    if (it == null)
                        requestLocationPart3(orderedProviders, index + 1)
                    else
                        onLocationResult(it, null)
                }
            )
        } catch (e: RuntimeException) {
            onLocationResult(null, e.message)
        }
    }

    external fun onLocationResult(location: Location?, error: String?)
    
    protected fun finalize() {
        nativeFinalize()
    }
    
    external fun nativeFinalize()
}
