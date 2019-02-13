/*
 * Apache 2.0 License
 *
 * Copyright (c) Sebastian Katzer 2017
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apache License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://opensource.org/licenses/Apache-2.0/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 */

// codebeat:disable[TOO_MANY_FUNCTIONS]

package org.apache.cordova.ijkplayer;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.util.Pair;
import android.view.View;
import android.content.Intent;
import android.widget.FrameLayout;
import android.view.LayoutInflater;
import android.widget.RelativeLayout;
import android.net.Uri;
import com.galaxy.client.R;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.lang.String;

import org.apache.cordova.ijkplayer.media.IjkVideoView;
import org.apache.cordova.ijkplayer.media.IRenderView;

public class IjkPlayerMgr extends CordovaPlugin {

    // Reference to the web view for static access
    private static WeakReference<CordovaWebView> webView = null;

    private String url5 = "rtmp://119.23.79.45:1935/live/B012";

    private IjkVideoView mVideoView;

    /**
     * Called after plugin construction and fields have been initialized.
     * Prefer to use pluginInitialize instead since there is no value in
     * having parameters on the initialize() function.
     */
    @Override
    public void initialize (CordovaInterface cordova, CordovaWebView webView) {
        IjkPlayerMgr.webView = new WeakReference<CordovaWebView>(webView);
    }

    /**
     * Called when the system is about to start resuming a previous activity.
     *
     * @param multitasking		Flag indicating if multitasking is turned on for app
     */
    public void onPause(boolean multitasking) {
    }

    /**
     * Called when the activity will start interacting with the user.
     *
     * @param multitasking Flag indicating if multitasking is turned on for app.
     */
    @Override
    public void onResume (boolean multitasking) {
    }

    /**
     * Called when the activity is becoming visible to the user.
     */
    public void onStart() {
    }

    /**
     * Called when the activity is no longer visible to the user.
     */
    public void onStop() {
    }

    /**
     * Called when the activity receives a new intent.
     */
    public void onNewIntent(Intent intent) {
    }

    /**
     * The final call you receive before your activity is destroyed.
     */
    public void onDestroy() {
    }

    /**
     * Executes the request.
     *
     * This method is called from the WebView thread. To do a non-trivial
     * amount of work, use:
     *      cordova.getThreadPool().execute(runnable);
     *
     * To run on the UI thread, use:
     *     cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action  The action to execute.
     * @param args    The exec() arguments in JSON form.
     * @param command The callback context used when calling back into
     *                JavaScript.
     *
     * @return Whether the action was valid.
     */
    @Override
    public boolean execute (final String action, final JSONArray args,
                            final CallbackContext command) throws JSONException {
        if ("deviceready".equals(action)) {
            final String url = args.getString(0);
            cordova.getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    createVideoView(url);
                    command.success(); // Thread-safe.
                }
            });
            return true;
        }
        return false;
    }

    private void createVideoView(String url) {
        Activity activity = cordova.getActivity();
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        RelativeLayout rootView = new RelativeLayout(activity);
        View content = LayoutInflater.from(activity).inflate(R.layout.activity_player, rootView);

        FrameLayout framelayout = (FrameLayout) activity.findViewById(android.R.id.content);

        View oldView = activity.findViewById(R.id.drawer_layout);
        if(oldView != null){
            IjkVideoView videoView = (IjkVideoView) oldView.findViewById(R.id.video_view);
            videoView.release(true);
            framelayout.removeView(oldView);
        }

        framelayout.addView(content, 0);

        mVideoView = (IjkVideoView) activity.findViewById(R.id.video_view);
        mVideoView.setAspectRatio(IRenderView.AR_MATCH_PARENT);
        mVideoView.setVideoURI(Uri.parse(url));
        mVideoView.start();
    }

}

// codebeat:enable[TOO_MANY_FUNCTIONS]
