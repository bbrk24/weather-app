package com.bbrk24.weatherapp

import android.view.View

class CustomOnClickListener(val rawPointer: Long): View.OnClickListener {
    override fun onClick(v: View) {
        nativeOnClick()
    }

    external fun nativeOnClick()
    
    protected fun finalize() {
        nativeFinalize()
    }
    
    external fun nativeFinalize()
}
